import SwiftUI

extension SettingsPane {
    public static func about(updater: Updater, @ViewBuilder extra: () -> some View = { EmptyView() }) -> SettingsPane {
        SettingsPane("About", systemImage: "info.circle.fill") {
            UpdatesSection(updater: updater)
            extra()
        }
    }
}

private struct UpdatesSection: View {
    let updater: Updater
    @AppStorage("checksForUpdates") private var checksForUpdates = true

    var body: some View {
        Section {
            Button(action: updater.checkForUpdates) {
                HStack {
                    Text("Check for Updates…")
                    Spacer()
                    Text(version)
                        .monospaced()
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Toggle("Automatically check for updates", isOn: $checksForUpdates)
        }
    }

    private var version: String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return "\(Bundle.main.version ?? "?") (\(build ?? "?"))"
    }
}
