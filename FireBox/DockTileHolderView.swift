//
//  DockTileHolderView.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import SwiftUI

struct DockTileHolderView: View {
    @State var image: NSImage = .init()
    let timer = Timer
        .publish(every: 1.0 / 60, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .onReceive(timer) { _ in nextFrame() }
    }

    func nextFrame() {
        guard let viewController = renderWindowController.contentViewController as? DockRenderViewController else {
            fatalError()
        }
        image = viewController.snapshot()
        DispatchQueue.main.async {
            tile.display()
        }
    }
}
