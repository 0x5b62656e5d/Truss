import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

public struct StartAtLoginToggle: View {
    @State private var isEnabled = SMAppService.mainApp.status == .enabled

    public init() {}

    public var body: some View {
        Toggle("Start at login", isOn: Binding {
            isEnabled
        } set: { enable in
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("%@: couldn't change start at login: %@", Bundle.main.name, error.localizedDescription)
            }
            isEnabled = SMAppService.mainApp.status == .enabled
        })
    }
}

public struct SettingsDataSection: View {
    @State private var isConfirmingReset = false

    private let defaults = UserDefaults.standard
    private let domain = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName

    public init() {}

    public var body: some View {
        Section("Settings Data") {
            LabeledContent("Export") {
                Button("Export settings…", action: export)
            }

            LabeledContent("Import") {
                Button("Import settings…", action: load)
            }

            LabeledContent("Reset") {
                Button("Reset settings and restart…") { isConfirmingReset = true }
            }
        }
        .alert("Reset all settings?", isPresented: $isConfirmingReset) {
            Button("Reset and Restart", role: .destructive) {
                defaults.removePersistentDomain(forName: domain)
                NSApp.relaunch()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(Bundle.main.name) will restart with its default settings.")
        }
    }

    private func export() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(Bundle.main.name) Settings.plist"
        panel.allowedContentTypes = [.propertyList]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try exportSettings(defaults, domain: domain, to: url)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func load() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.propertyList]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try importSettings(defaults, domain: domain, from: url)
            NSApp.relaunch()
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}

func exportSettings(_ defaults: UserDefaults, domain: String, to url: URL) throws {
    let settings = defaults.persistentDomain(forName: domain) ?? [:]
    try PropertyListSerialization.data(fromPropertyList: settings, format: .xml, options: 0).write(to: url)
}

func importSettings(_ defaults: UserDefaults, domain: String, from url: URL) throws {
    let data = try Data(contentsOf: url)
    guard let settings = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
        throw CocoaError(.fileReadCorruptFile)
    }
    defaults.setPersistentDomain(settings, forName: domain)
}
