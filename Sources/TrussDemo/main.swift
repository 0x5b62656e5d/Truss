import AppKit
import SwiftUI
import Truss

struct DisplaySection: View {
    @AppStorage("showsMenubarIcon") private var showsIcon = true

    var body: some View {
        Section("Display") {
            Toggle("Show menubar icon", isOn: $showsIcon)
        }
    }
}

struct BatterySection: View {
    @AppStorage("notifiesOnLowBattery") private var notifies = true
    @AppStorage("lowBatteryLevel") private var level = 20

    var body: some View {
        Section("Alerts") {
            Toggle("Notify when battery is low", isOn: $notifies)
            Picker("Low battery level", selection: $level) {
                ForEach([10, 20, 30], id: \.self) { Text("\($0)%") }
            }
        }
    }
}

func argument(_ name: String) -> String? {
    CommandLine.arguments.drop { $0 != name }.dropFirst().first
}

final class Demo: NSObject, NSApplicationDelegate {
    let settings = SettingsWindow(panes: [
        SettingsPane("General", systemImage: "gearshape.fill") {
            Section("Startup") { StartAtLoginToggle() }
            DisplaySection()
            SettingsDataSection()
        },
        SettingsPane("Battery", systemImage: "bolt.fill", color: .orange, group: "Notifications") {
            BatterySection()
        },
        .about(updater: Updater(repo: argument("--repo") ?? "0x5b62656e5d/Truss")),
    ])

    func applicationDidFinishLaunching(_ notification: Notification) {
        let arguments = CommandLine.arguments
        if arguments.contains("--dark") { NSApp.appearance = NSAppearance(named: .darkAqua) }
        if arguments.contains("--light") { NSApp.appearance = NSAppearance(named: .aqua) }
        settings.show(argument("--pane"))
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let demo = Demo()
NSApplication.shared.delegate = demo
NSApp.setActivationPolicy(.regular)
NSApp.run()
