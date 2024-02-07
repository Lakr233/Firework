//
//  main.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/8.
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
    func applicationDidFinishLaunching(_: Notification) {
        tile.contentView = NSHostingView(rootView: tileHolder)
        tile.display()
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        FireworkEmitter.launch()
        return false
    }
}

let appDelegate = AppDelegate()
NSApplication.shared.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
