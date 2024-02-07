//
//  DockRenderViewController.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import SwiftUI

class DockRenderViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        view = NSHostingView(rootView: DockCanvasView())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewWillLayout() {
        super.viewWillLayout()
        view.frame = .init(origin: .zero, size: renderSize)
    }

    func snapshot() -> NSImage {
        guard let window = view.window else { return .init() }
        let cgImage = CGWindowListCreateImage(
            CGRect.null,
            CGWindowListOption.optionIncludingWindow,
            CGWindowID(window.windowNumber),
            CGWindowImageOption.bestResolution
        )
        let image = NSImage(cgImage: cgImage!, size: window.frame.size)
        return image
    }
}
