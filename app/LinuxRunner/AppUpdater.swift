import SwiftUI
import UIKit

// Foreground downloads: the OS copies the document to LCSign through Open In.
// A bare loadcontroller:// URL cannot grant access to our private IPA file.
@MainActor final class AppUpdater: ObservableObject {
    static let shared = AppUpdater()
    @Published private(set) var message = "Updates are downloaded from sonnx0868/LinuxRunner."
    @Published private(set) var busy = false
    @Published private(set) var progress: Double?
    @Published private(set) var available: AppUpdateManifest?
    @Published private(set) var readyURL: URL?
    @Published var presentHandoff = false
    private var operation: Task<Void, Never>?
    private var transfer: AppUpdateTransfer?
    private var lastAttempt = Date.distantPast
    private let defaults = UserDefaults.standard
    var autoDownload: Bool {
        get { defaults.object(forKey: "LinuxRunner.update.autoDownload") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "LinuxRunner.update.autoDownload") }
    }
    var channel: String { Bundle.main.object(forInfoDictionaryKey: "LinuxRunnerUpdateChannel") as? String ?? "disabled" }
    var installedBuild: Int { Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0") ?? 0 }
    var installedVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?" }

    func check(automatic: Bool = false) {
        guard !busy, ["m2-jit", "m2-interpreter"].contains(channel) else { return }
        if automatic {
            guard autoDownload, Date().timeIntervalSince(lastAttempt) > 6 * 3600 else { return }
        }
        lastAttempt = Date()
        busy = true; message = "Checking for updates…"
        operation = Task {
            defer { busy = false; progress = nil; operation = nil; transfer = nil }
            do {
                let releasesURL = URL(string: "https://api.github.com/repos/\(AppUpdateManifest.repository)/releases?per_page=30")!
                let releases = try JSONDecoder().decode([AppUpdateRelease].self, from: await metadata(releasesURL))
                var newest: AppUpdateManifest?
                for release in releases where !release.draft && !release.prerelease {
                    guard let asset = release.assets.first(where: { $0.name == "update-\(channel).json" }),
                          AppUpdateManifest.isReleaseURL(asset.browser_download_url) else { continue }
                    let candidate = try JSONDecoder().decode(AppUpdateManifest.self, from: await metadata(asset.browser_download_url))
                    // Bundle IDs may be changed by signing tools. Match the build's original identity.
                    try candidate.validate(channel: channel, bundleID: Bundle.main.object(forInfoDictionaryKey: "LinuxRunnerUpdateBundleID") as? String ?? "dev.linuxrunner.app")
                    if newest == nil || candidate.build > newest!.build { newest = candidate }
                }
                try Task.checkCancellation()
                guard let newest else { message = "No update has been published for this build yet."; return }
                guard newest.build > installedBuild else {
                    available = nil; readyURL = nil; message = "You have the latest published build."; return
                }
                available = newest
                message = "Version \(newest.version) · build \(newest.build) is available."
                if autoDownload { try await download(newest) }
            } catch is CancellationError { message = "Update cancelled." }
            catch { message = Task.isCancelled ? "Update cancelled." : error.localizedDescription }
        }
    }

    private func metadata(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("LinuxRunner-Updater", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw AppUpdateError.http((response as? HTTPURLResponse)?.statusCode ?? 0) }
        guard data.count < 2 * 1024 * 1024 else { throw AppUpdateError.invalidManifest }
        return data
    }

    func downloadAvailable() {
        guard !busy, let available else { return }
        busy = true
        operation = Task {
            defer { busy = false; progress = nil; operation = nil; transfer = nil }
            do { try await download(available) }
            catch { message = Task.isCancelled ? "Update cancelled." : error.localizedDescription }
        }
    }

    private func download(_ manifest: AppUpdateManifest) async throws {
        readyURL = nil; message = "Downloading update…"; progress = 0
        let directory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("AppUpdates", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // One stable cache path bounds disk use; verification also covers a saved IPA after relaunch.
        let destination = directory.appendingPathComponent("LinuxRunner-\(channel).ipa")
        let downloader = AppUpdateTransfer()
        transfer = downloader
        let url = try await downloader.run(manifest: manifest, destination: destination) { [weak self] fraction in
            Task { @MainActor in self?.progress = fraction }
        }
        try Task.checkCancellation()
        readyURL = url; message = "Update ready. Choose LCSign in Open In, then sign and install."
        presentHandoff = true
    }

    func cancel() { operation?.cancel(); transfer?.cancel() }
}

private final class AppUpdateTransfer: NSObject, URLSessionDownloadDelegate {
    private var manifest: AppUpdateManifest!
    private var destination: URL!
    private var continuation: CheckedContinuation<URL, Error>?
    private var report: ((Double) -> Void)?
    private var task: URLSessionDownloadTask?
    private var session: URLSession?
    private var lastProgress = Date.distantPast

    func run(manifest: AppUpdateManifest, destination: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        self.manifest = manifest; self.destination = destination; report = progress
        if FileManager.default.fileExists(atPath: destination.path) {
            let saved = try await Task.detached(priority: .utility) { (try? manifest.verifyFile(destination)) != nil }.value
            if saved { return destination }
        }
        try Task.checkCancellation()
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 60
            config.timeoutIntervalForResource = 30 * 60
            let queue = OperationQueue(); queue.maxConcurrentOperationCount = 1; queue.qualityOfService = .utility
            let session = URLSession(configuration: config, delegate: self, delegateQueue: queue)
            self.session = session
            let request = URLRequest(url: manifest.ipaURL)
            task = session.downloadTask(with: request); task?.priority = URLSessionTask.lowPriority; task?.resume()
        }
    }
    func cancel() { task?.cancel() }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesWritten <= manifest.size else { downloadTask.cancel(); return }
        if Date().timeIntervalSince(lastProgress) >= 0.2 {
            lastProgress = Date(); report?(min(1, Double(totalBytesWritten) / Double(manifest.size)))
        }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let http = downloadTask.response as? HTTPURLResponse, http.statusCode == 200 else { throw AppUpdateError.http((downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0) }
            try manifest.verifyFile(location)
            if FileManager.default.fileExists(atPath: destination.path) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: location)
            } else { try FileManager.default.moveItem(at: location, to: destination) }
            finish(.success(destination))
        } catch { finish(.failure(error)) }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { finish(.failure(error)) }
    }
    private func finish(_ result: Result<URL, Error>) {
        continuation?.resume(with: result); continuation = nil
        session?.finishTasksAndInvalidate(); session = nil; task = nil
    }
}

struct AppUpdateSettingsView: View {
    @ObservedObject var updater: AppUpdater
    @State private var automatic = AppUpdater.shared.autoDownload
    var body: some View {
        List {
            Section("LinuxRunner Updates") {
                Text("Installed: \(updater.installedVersion) · build \(updater.installedBuild)")
                Toggle("Automatically Download Updates", isOn: $automatic).onChange(of: automatic) { updater.autoDownload = $0 }
                Text(updater.message).font(.footnote)
                if let progress = updater.progress { ProgressView(value: progress) }
                if updater.busy { Button("Cancel", action: updater.cancel) }
                else {
                    Button("Check Now") { updater.check() }
                    if updater.available != nil && updater.readyURL == nil { Button("Download Update", action: updater.downloadAvailable) }
                    if updater.readyURL != nil { Button("Send IPA to LCSign") { updater.presentHandoff = true } }
                }
            }
            Section {
                Text("When the IPA is ready, choose LCSign in Open In. Sign with the same bundle ID and signing settings to update the installed app. Keep LinuxRunner open while downloading.")
                Text("LCSign 1.0 build 6 receives IPA documents. iPadOS requires you to choose the receiving app; signing and installation happen in LCSign.")
            }.font(.footnote).foregroundColor(.secondary)
        }.navigationTitle("App Updates")
    }
}

// Presented inside the current scene, including iPad popover anchoring. Never
// launches a second app before the document handoff has been accepted by iOS.
struct AppUpdateHandoff: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> AppUpdateHandoffController { AppUpdateHandoffController(url: url) }
    func updateUIViewController(_ controller: AppUpdateHandoffController, context: Context) { }
}

final class AppUpdateHandoffController: UIViewController, UIDocumentInteractionControllerDelegate {
    private let document: UIDocumentInteractionController
    private var shown = false
    init(url: URL) {
        document = UIDocumentInteractionController(url: url)
        super.init(nibName: nil, bundle: nil)
        document.uti = "com.apple.itunes.ipa"; document.name = url.lastPathComponent; document.delegate = self
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .systemBackground
        let button = UIButton(type: .system)
        button.setTitle("Choose LCSign to receive the IPA", for: .normal)
        button.addTarget(self, action: #selector(openDocument), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(button)
        NSLayoutConstraint.activate([button.centerXAnchor.constraint(equalTo: view.centerXAnchor), button.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
    }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); if !shown { shown = true; openDocument() } }
    @objc private func openDocument() {
        let rect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        if !document.presentOpenInMenu(from: rect, in: view, animated: true) {
            let share = UIActivityViewController(activityItems: [document.url!], applicationActivities: nil)
            share.popoverPresentationController?.sourceView = view; share.popoverPresentationController?.sourceRect = rect
            present(share, animated: true)
        }
    }
    @objc private func close() { dismiss(animated: true) }
    func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) { dismiss(animated: true) }
}
