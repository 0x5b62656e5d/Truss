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
            HStack(spacing: 12) {
                // NSApp.applicationIconImage can hold on to a stale placeholder, so ask for the icon Finder shows.
                Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                    .resizable()
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Bundle.main.name)
                        .font(.headline)
                    Text("Version \(version)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Check for Updates…", action: updater.checkForUpdates)
            }
            .padding(.vertical, 4)

            Toggle("Automatically check for updates", isOn: $checksForUpdates)
        }
    }

    private var version: String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return "\(Bundle.main.version ?? "?") (\(build ?? "?"))"
    }
}
