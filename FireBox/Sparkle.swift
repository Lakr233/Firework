//
//  Sparkle.swift
//  Firework
//
//  Created by 秋星桥 on 2024/2/7.
//

import AppKit
import Foundation

private let sparkle: NSImage = {
    let size = CGSize(width: 64, height: 64)
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    let radius = min(size.width, size.height) / 2

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            NSColor.white.cgColor,
//            NSColor.clear.cgColor,
        ] as CFArray,
        locations: [0, 1]
    )

    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )!

    context.saveGState()
    context.addArc(
        center: center,
        radius: radius,
        startAngle: 0,
        endAngle: CGFloat.pi * 2,
        clockwise: false
    )
    context.clip()

    let startPoint = CGPoint(x: center.x, y: center.y - radius)
    let endPoint = CGPoint(x: center.x, y: center.y + radius)
    context.drawRadialGradient(
        gradient!,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: []
    )

    context.restoreGState()

    let cgImage = context.makeImage()
    let finalImage = NSImage(cgImage: cgImage!, size: size)

    return finalImage
}()

let coreSparkle: CGImage = {
    var rect = CGRect(
        x: 0,
        y: 0,
        width: sparkle.size.width,
        height: sparkle.size.height
    )
    return sparkle.cgImage(
        forProposedRect: &rect,
        context: nil,
        hints: nil
    )!
}()
