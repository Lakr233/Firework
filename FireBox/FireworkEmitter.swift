//
//  FireworkEmitter.swift
//  FireBox
//
//  Created for FireBox on 2024/2/9.
//

import AppKit

enum FireworkEmitter {
    @MainActor
    static func launch() {
        let mouseLocation = NSEvent.mouseLocation
        // Pick the screen the cursor is currently on, so fireworks appear
        // on whichever display the mouse lives instead of always the main one.
        let screen = NSScreen.screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        } ?? NSScreen.main
        guard let screen else { return }
        ViewModel.shared.fireCount &+= 1

        // FIXME: Use Combine for debouncing
        ViewModel.shared.smoke = true
        ViewModel.shared.wiggle = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            ViewModel.shared.smoke = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            ViewModel.shared.wiggle = false
        }

        let controller = FireworkController(screen: screen)
        controller.window?.setFrameOrigin(screen.frame.origin)
        controller.window?.setContentSize(screen.frame.size)
        controller.window?.orderFrontRegardless()

        // Move the dimming overlay onto the same screen as the cursor.
        dimmWindowController.window?.setFrameOrigin(screen.frame.origin)
        dimmWindowController.window?.setContentSize(screen.frame.size)
        dimmWindowController.window?.orderFront(nil)

        // NSEvent.mouseLocation is in global coordinates; convert it to the
        // firework window's local space by subtracting the screen origin.
        let localLocation = CGPoint(
            x: mouseLocation.x - screen.frame.origin.x,
            y: mouseLocation.y - screen.frame.origin.y
        )
        guard let fireworkView = controller
            .window?
            .contentViewController?
            .view as? FireworkView
        else { fatalError() }

        dimmWindowController.dimm()
        let message = ViewModel.shared.messages.randomElement()?.text
        fireworkView.launchFireWork(atLocation: localLocation, message: message) {
            fireworkView.fadeOut {
                controller.close()
            }
        }
    }
}
