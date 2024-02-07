//
//  FireworkController.swift
//  Firework
//
//  Created by 秋星桥 on 2024/2/7.
//

import AppKit
import Foundation

class FireworkController: NSWindowController {
    override init(window: NSWindow?) {
        super.init(window: window)
        contentViewController = FireworkViewController()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    convenience init(screen: NSScreen) {
        let window = NoneInteractWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        self.init(window: window)
    }
}

class FireworkViewController: NSViewController {
    override func loadView() {
        view = FireworkView()
    }
}
