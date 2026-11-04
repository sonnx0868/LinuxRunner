import Foundation
import CryptoKit

@main struct UpdateManifestProbe {
    static func main() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let bytes = Data([0x50, 0x4b, 0x03, 0x04, 1, 2, 3])
        try bytes.write(to: file)
        let hash = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let value: [String: Any] = ["schema": 1, "channel": "m2-jit", "bundleID": "dev.linuxrunner.app", "version": "1.1.0", "build": 1007, "sourceCommit": String(repeating: "a", count: 40), "size": bytes.count, "sha256": hash, "ipaURL": "https://github.com/sonnx0868/LinuxRunner/releases/download/m2-b1007/LinuxRunner.ipa"]
        func decode(_ values: [String: Any]) throws -> AppUpdateManifest {
            try JSONDecoder().decode(AppUpdateManifest.self, from: JSONSerialization.data(withJSONObject: values))
        }
        let valid = try decode(value)
        try valid.validate(channel: "m2-jit", bundleID: "dev.linuxrunner.app")
        try valid.verifyFile(file)
        func rejects(_ name: String, _ body: () throws -> Void) {
            do { try body(); fatalError("Accepted invalid update: \(name)") } catch { }
        }
        rejects("wrong flavor") { try valid.validate(channel: "m2-interpreter", bundleID: "dev.linuxrunner.app") }
        rejects("wrong app") { try valid.validate(channel: "m2-jit", bundleID: "another.app") }
        for url in ["http://github.com/sonnx0868/LinuxRunner/releases/download/v/a.ipa", "https://github.com/attacker/LinuxRunner/releases/download/v/a.ipa", "https://github.com/sonnx0868/LinuxRunner/releases/download/v/a.ipa?redirect=1", "https://example.com/a.ipa"] {
            var bad = value; bad["ipaURL"] = url
            rejects("untrusted URL") { try decode(bad).validate(channel: "m2-jit", bundleID: "dev.linuxrunner.app") }
        }
        var bad = value; bad["size"] = AppUpdateManifest.maximumSize + 1
        rejects("oversize") { try decode(bad).validate(channel: "m2-jit", bundleID: "dev.linuxrunner.app") }
        try Data([0x50, 0x4b, 0x03, 0x04, 1, 2, 4]).write(to: file)
        rejects("corruption") { try valid.verifyFile(file) }
        try Data([0x50, 0x4b]).write(to: file)
        rejects("truncated") { try valid.verifyFile(file) }
        print("PASS update channel, app identity, URL, size, SHA256 and truncation checks")
    }
}
