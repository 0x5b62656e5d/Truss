# Truss

Shared pieces for macOS apps: a settings window with a sidebar of panes, and an updater that installs new versions from GitHub releases.

- `SettingsWindow` shows `SettingsPane`s, each a grouped `Form` with an icon tile in the sidebar. Panes can share a sidebar heading through `group`. An app without a Dock icon gets a menu bar while the window is open.
- `.about(updater:)` adds an About pane with a Check for Updates button, the app's version, and an automatic-updates toggle.
- `StartAtLoginToggle` and `SettingsDataSection` (export, import and reset settings) are ready-made rows.
- `Updater` checks daily, offers the release notes, and replaces the app in place before relaunching it.

## Usage

```swift
import Truss

let updater = Updater(repo: "owner/repo")
updater.start()

let settings = SettingsWindow(panes: [
    SettingsPane("General", systemImage: "gearshape.fill") {
        Section("Startup") { StartAtLoginToggle() }
        Section("Display") { Toggle("Show menubar icon", isOn: $showIcon) }
        SettingsDataSection()
    },
    SettingsPane("Battery", systemImage: "bolt.fill", color: .orange, group: "Notifications") { ... },
    .about(updater: updater),
])

settings.show()
settings.show("About")
```

`Updater` is an `NSObject`, so a menu item can target it with `#selector(Updater.checkForUpdates)`.

## Installing

Add `https://github.com/0x5b62656e5d/Truss` as a Swift package dependency and link the `Truss` library. It needs macOS 27.

## Releases

The updater reads the repository's latest GitHub release. Each release should:

- be tagged `vX.Y.Z`, matching the app's `CFBundleShortVersionString`;
- have an `<AppName>.zip` asset containing `<AppName>.app`, where `<AppName>` is the app's `CFBundleName`;
- be signed by the same certificate as the running app, or the update is refused.

Its preferences live in the app's standard defaults under `checksForUpdates`, `skippedVersion` and `lastUpdateCheck`.
