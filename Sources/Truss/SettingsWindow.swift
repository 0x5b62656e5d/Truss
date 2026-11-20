import AppKit
import SwiftUI

public final class SettingsWindow: NSObject, NSWindowDelegate {
    private let window = CloseableWindow(
        contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
        backing: .buffered,
        defer: true
    )
    private let selection: SettingsSelection
    private var restoresAccessory = false

    public init(panes: [SettingsPane]) {
        selection = SettingsSelection(panes.first?.title ?? "")
        super.init()
        window.title = "Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: SettingsView(panes: panes, selection: selection))
        window.center()
    }

    public func show(_ title: String? = nil) {
        if let title { selection.title = title }

        // An app without a Dock icon never gets the menu bar, so it becomes a regular app while this is open.
        if NSApp.activationPolicy() == .accessory {
            NSApp.setActivationPolicy(.regular)
            restoresAccessory = true
        }

        NSApp.activateForcefully()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        // Otherwise the first control opens with a focus ring, as if it had been clicked.
        window.makeFirstResponder(nil)
    }

    public func windowWillClose(_ notification: Notification) {
        guard restoresAccessory else { return }
        NSApp.setActivationPolicy(.accessory)
        restoresAccessory = false
    }
}

private final class CloseableWindow: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command, event.charactersIgnoringModifiers == "w" else {
            return super.performKeyEquivalent(with: event)
        }
        performClose(nil)
        return true
    }
}
