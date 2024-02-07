//
//  FireworkEmitter.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import AppKit

enum FireworkEmitter {
    static func launch() {
        guard let screen = NSScreen.main else { return }
        ViewModel.shared.fireCount += 1

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

        let mouseLocation = NSEvent.mouseLocation
        guard let fireworkView = controller
            .window?
            .contentViewController?
            .view as? FireworkView
        else { fatalError() }

        DispatchQueue.global().async {
            let waitBegin = Date()
            while !fireworkView.isPrepared,
                  Date().timeIntervalSince(waitBegin) < 5
            { usleep(50000) }

            DispatchQueue.main.async {
                dimmWindowController.dimm()
                fireworkView.launchFireWork(atLocation: mouseLocation) {
                    fireworkView.fadeOut {
                        controller.close()
                    }
                }
            }
        }
    }
}
