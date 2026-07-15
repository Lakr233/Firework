import AppKit
import SwiftUI

final class CelebrationWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "Firework Library")
        window.contentMinSize = .init(width: 440, height: 300)
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: CelebrationLibraryView())
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func present() {
        guard let window else { return }
        if !window.isVisible {
            window.center()
        }
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
