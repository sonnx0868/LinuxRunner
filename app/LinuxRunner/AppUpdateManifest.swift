import Foundation
import CryptoKit

enum AppUpdateError: LocalizedError {
    case invalidManifest, incompatibleBuild, invalidDownload, checksumMismatch, http(Int)
    var errorDescription: String? {
        switch self {
        case .invalidManifest: return "Invalid update information."
        case .incompatibleBuild: return "This update belongs to a different LinuxRunner build."
        case .invalidDownload: return "The downloaded IPA is incomplete or invalid. Try downloading again."
        case .checksumMismatch: return "The IPA checksum does not match. The file was rejected."
        case .http(let code): return "Update server returned HTTP \(code). Try again later."
        }
    }
}

struct AppUpdateManifest: Codable, Equatable {
    let schema: Int
    let channel: String
    let bundleID: String
    let version: String
    let build: Int
    let sourceCommit: String
    let ipaURL: URL
    let sha256: String
    let size: Int64

    static let repository = "sonnx0868/LinuxRunner"
    static let maximumSize: Int64 = 2 * 1024 * 1024 * 1024

    static func isReleaseURL(_ url: URL) -> Bool {
        url.scheme == "https" && url.host == "github.com" && url.user == nil && url.password == nil &&
        url.port == nil && url.query == nil && url.fragment == nil &&
        url.path.hasPrefix("/\(repository)/releases/download/") &&
        !url.pathComponents.contains("..")
    }

    func validate(channel expectedChannel: String, bundleID expectedBundle: String) throws {
        guard schema == 1, build > 0, !version.isEmpty, version.count < 40,
              ["m2-jit", "m2-interpreter"].contains(channel),
              sourceCommit.range(of: "^[0-9a-f]{40}$", options: .regularExpression) != nil,
              sha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
              size > 4, size <= Self.maximumSize,
              Self.isReleaseURL(ipaURL), ipaURL.pathExtension == "ipa" else {
            throw AppUpdateError.invalidManifest
        }
        guard channel == expectedChannel, bundleID == expectedBundle else { throw AppUpdateError.incompatibleBuild }
    }

    func verifyFile(_ url: URL) throws {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        guard try handle.seekToEnd() == UInt64(size) else { throw AppUpdateError.invalidDownload }
        try handle.seek(toOffset: 0)
        guard try handle.read(upToCount: 4) == Data([0x50, 0x4b, 0x03, 0x04]) else { throw AppUpdateError.invalidDownload }
        try handle.seek(toOffset: 0)
        var hash = SHA256()
        while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty { hash.update(data: data) }
        let actual = hash.finalize().map { String(format: "%02x", $0) }.joined()
        guard actual == sha256 else { throw AppUpdateError.checksumMismatch }
    }
}

struct AppUpdateRelease: Decodable {
    struct Asset: Decodable {
        let name: String
        let browser_download_url: URL
    }
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]
}
