//
//  DockRenderController.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import AppKit

class DockRenderController: NSWindowController {
    override init(window: NSWindow?) {
        super.init(window: window)
        contentViewController = DockRenderViewController()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    convenience init(screen: NSScreen) {
        let window = NoneInteractWindow(
            contentRect: .init(origin: .zero, size: renderSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        self.init(window: window)
    }
}
