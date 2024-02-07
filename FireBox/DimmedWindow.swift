//
//  DimmedWindow.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import AppKit
import Foundation

class DimmWindowController: NSWindowController {
    override init(window: NSWindow?) {
        super.init(window: window)
        contentViewController = DimmedViewController()
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

    func dimm() {
        (contentViewController as? DimmedViewController)?.dimm()
    }
}

class DimmedViewController: NSViewController {
    private var isDimmed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        view.layer?.opacity = 0
    }

    func dimm() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(cancelDimm),
            object: nil
        )
        perform(#selector(cancelDimm), with: nil, afterDelay: 3)

        guard !isDimmed else { return }
        isDimmed = true
        var fromValue = 0.0
        if let presentation = view.layer?.presentation() {
            fromValue = Double(presentation.opacity)
        }
        view.layer?.removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = fromValue
        animation.toValue = 0.5
        animation.duration = 1
        animation.isRemovedOnCompletion = true
        view.layer?.add(animation, forKey: "opacity")
        view.layer?.opacity = 0.5
    }

    @objc func cancelDimm() {
        isDimmed = false
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.5
        animation.toValue = 0
        animation.duration = 1
        animation.isRemovedOnCompletion = true
        view.layer?.add(animation, forKey: "opacity")
        view.layer?.opacity = 0
    }
}
