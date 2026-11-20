import AppKit

public final class Updater: NSObject {
    private static let checkInterval: TimeInterval = 24 * 60 * 60
    private static let pollInterval: TimeInterval = 60 * 60

    private let latestRelease: URL
    private let defaults = UserDefaults.standard
    private var isChecking = false
    private var window: UpdateWindow?

    public init(repo: String) {
        latestRelease = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
    }

    public func start() {
        checkIfDue()
        Timer.scheduledTimer(timeInterval: Self.pollInterval, target: self, selector: #selector(checkIfDue), userInfo: nil, repeats: true)
    }

    @objc public func checkForUpdates() {
        check(manually: true)
    }

    @objc private func checkIfDue() {
        let checksForUpdates = defaults.object(forKey: "checksForUpdates") as? Bool ?? true
        let lastCheck = defaults.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        guard checksForUpdates, -lastCheck.timeIntervalSinceNow >= Self.checkInterval else { return }
        check(manually: false)
    }

    private func check(manually: Bool) {
        if let window { return window.show() }
        guard !isChecking else { return }
        isChecking = true

        Task { [self] in
            defer { isChecking = false }
            let release: Release
            do {
                release = try await fetchLatest()
                defaults.set(Date(), forKey: "lastUpdateCheck")
            } catch {
                NSLog("%@: update check failed: %@", Bundle.main.name, error.localizedDescription)
                if manually { Self.alert("Couldn't check for updates", error.localizedDescription) }
                return
            }

            let current = Bundle.main.version ?? "0"
            guard isNewer(release.version, than: current) else {
                if manually { Self.alert("You're up to date", "\(Bundle.main.name) \(current) is the latest version.") }
                return
            }
            guard manually || release.version != defaults.string(forKey: "skippedVersion") else { return }

            window = UpdateWindow(version: release.version, current: current, notes: release.body ?? "") { [weak self] choice in
                self?.chose(choice, release)
            }
            window?.show()
        }
    }

    private func chose(_ choice: UpdateWindow.Choice, _ release: Release) {
        switch choice {
        case .install:
            Task {
                do {
                    try await install(release)
                } catch {
                    NSLog("%@: update failed: %@", Bundle.main.name, error.localizedDescription)
                    window?.close()
                    window = nil
                    if Self.alert("Couldn't install the update", error.localizedDescription, buttons: ["Open Release Page", "Cancel"]) == .alertFirstButtonReturn {
                        NSWorkspace.shared.open(release.htmlUrl)
                    }
                }
            }
        case .skip:
            defaults.set(release.version, forKey: "skippedVersion")
            window = nil
        case .later:
            window = nil
        }
    }

    private func install(_ release: Release) async throws {
        let name = Bundle.main.name
        guard let asset = release.assets.first(where: { $0.name == "\(name).zip" }) else { throw UpdateError("The release has no \(name).zip.") }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let (zip, response) = try await URLSession.shared.download(from: asset.browserDownloadUrl)
        defer { try? FileManager.default.removeItem(at: zip) }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateError("The download failed.") }

        let unzip = try Process.run(URL(fileURLWithPath: "/usr/bin/ditto"), arguments: ["-x", "-k", zip.path, folder.path])
        unzip.waitUntilExit()
        let app = folder.appendingPathComponent("\(name).app")
        guard unzip.terminationStatus == 0, Bundle(url: app)?.version == release.version else {
            throw UpdateError("The download isn't \(name) \(release.version).")
        }
        guard Self.isSignedLikeThisApp(app) else { throw UpdateError("The download isn't signed by \(name)'s developer.") }

        _ = try FileManager.default.replaceItemAt(Bundle.main.bundleURL, withItemAt: app)
        NSApp.relaunch()
    }

    private static func isSignedLikeThisApp(_ app: URL) -> Bool {
        var running: SecCode?, own: SecStaticCode?, requirement: SecRequirement?, new: SecStaticCode?
        guard SecCodeCopySelf([], &running) == errSecSuccess, let running,
              SecCodeCopyStaticCode(running, [], &own) == errSecSuccess, let own,
              SecCodeCopyDesignatedRequirement(own, [], &requirement) == errSecSuccess, let requirement,
              SecStaticCodeCreateWithPath(app as CFURL, [], &new) == errSecSuccess, let new else { return false }
        return SecStaticCodeCheckValidity(new, SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate), requirement) == errSecSuccess
    }

    private func fetchLatest() async throws -> Release {
        let (data, response) = try await URLSession.shared.data(from: latestRelease)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateError("GitHub didn't return the latest release.") }
        return try Release.decode(data)
    }

    @discardableResult
    private static func alert(_ title: String, _ text: String, buttons: [String] = ["OK"]) -> NSApplication.ModalResponse {
        NSApp.activateForcefully()
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        buttons.forEach { alert.addButton(withTitle: $0) }
        return alert.runModal()
    }
}

func isNewer(_ version: String, than current: String) -> Bool {
    version.compare(current, options: .numeric) == .orderedDescending
}

struct Release: Decodable {
    struct Asset: Decodable {
        let name: String
        let browserDownloadUrl: URL
    }

    let tagName: String
    let body: String?
    let htmlUrl: URL
    let assets: [Asset]

    var version: String { tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName }

    static func decode(_ data: Data) throws -> Release {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Release.self, from: data)
    }
}

private struct UpdateError: LocalizedError {
    let errorDescription: String?

    init(_ description: String) {
        errorDescription = description
    }
}

extension Bundle {
    var name: String {
        infoDictionary?["CFBundleName"] as? String ?? ProcessInfo.processInfo.processName
    }

    var version: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
