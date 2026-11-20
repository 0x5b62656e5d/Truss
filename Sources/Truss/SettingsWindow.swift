import AppKit
import SwiftUI

public final class SettingsWindow {
    private let window = CloseableWindow(
        contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
        backing: .buffered,
        defer: true
    )
    private let selection: SettingsSelection

    public init(panes: [SettingsPane]) {
        selection = SettingsSelection(panes.first?.title ?? "")
        window.title = "Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(panes: panes, selection: selection))
        window.center()
    }

    public func show(_ title: String? = nil) {
        if let title { selection.title = title }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
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
