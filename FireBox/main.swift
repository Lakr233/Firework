//
//  main.swift
//  FireBox
//
//  Created for FireBox on 2024/2/8.
//

import AppKit
import SwiftUI

guard let screen = NSScreen.main else {
    fatalError("unable to locate main screen")
}

let renderEdgeSize = 128
let renderSize = CGSize(width: CGFloat(renderEdgeSize), height: CGFloat(renderEdgeSize))

let renderWindowController = DockRenderController(screen: screen)
renderWindowController.window?.setFrameOrigin(.init(x: -50, y: -renderEdgeSize - 50))
renderWindowController.window?.setContentSize(renderSize)
renderWindowController.window?.orderFront(nil)

let dimmWindowController = DimmWindowController(screen: screen)
dimmWindowController.window?.setFrameOrigin(screen.frame.origin)
dimmWindowController.window?.setContentSize(screen.frame.size)
dimmWindowController.window?.orderFront(nil)

let tile: NSDockTile = NSApplication.shared.dockTile
let tileHolder = DockTileHolderView()

class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var celebrationWindowController = CelebrationWindowController()

    func applicationDidFinishLaunching(_: Notification) {
        tile.contentView = NSHostingView(rootView: tileHolder)
        tile.display()
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        FireworkEmitter.launch()
        return false
    }

    func applicationDockMenu(_: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let openItem = NSMenuItem(
            title: String(localized: "Open Firework Library…"),
            action: #selector(openCelebrationLibrary),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        let launchItem = NSMenuItem(
            title: String(localized: "Random Launch"),
            action: #selector(launchRandomFirework),
            keyEquivalent: ""
        )
        launchItem.target = self
        menu.addItem(launchItem)
        return menu
    }

    @objc private func openCelebrationLibrary() {
        celebrationWindowController.present()
    }

    @MainActor
    @objc private func launchRandomFirework() {
        FireworkEmitter.launch()
    }
}

let appDelegate = AppDelegate()
NSApplication.shared.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
