//
//  FireworkView.swift
//  Firework
//
//  Created by Soulghost on 2024/2/7.
//

import Cocoa
import MetalKit
import simd
import SwiftUI

class FireworkView: NSView {
    private static let displayP3Colors: [simd_float3] = [
        .init(1.00, 0.35, 0.21),
        .init(0.22, 0.74, 0.97),
        .init(0.75, 0.52, 0.99),
        .init(0.20, 0.83, 0.60),
        .init(0.98, 0.75, 0.14),
    ]

    private var dummyMTKView: MTKView!
    private var metalLayer = CAMetalLayer()
    private var device: MTLDevice!
    private var renderer = FireworkRenderer()

    var isPrepared: Bool { renderer.isPrepared }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func layout() {
        super.layout()
        updateMetalLayerGeometry()
    }

    private func updateMetalLayerGeometry() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
        metalLayer.frame = bounds
        metalLayer.contentsScale = scale
        metalLayer.drawableSize = .init(
            width: bounds.width * scale,
            height: bounds.height * scale
        )
    }

    var rootEmitter: EmitterControl {
        let viewSize = bounds.size
        let velocity = Float(viewSize.height) * 0.8
        let rootPosition = simd_float2(Float(viewSize.width) * 0.5, Float(viewSize.height))
        return EmitterControl(
            birthRate: 1,
            lifetime: 2,
            velocity: velocity,
            velocityRange: 100.0,
            yAcceleration: -velocity * 0.5,
            emitAngle: Float.pi * 1.5,
            emitAngleRange: Float.pi * (18.0 / 180.0),
            emitterPosition: rootPosition,
            emitterSize: 4,
            color: Self.randomLinearDisplayP3Color(),
            duration: 1.0,
            beginTime: 0.0
        )
    }

    var fireworkEmitter: EmitterControl {
        var emitter = EmitterControl(
            birthRate: 512,
            lifetime: 3,
            velocity: 70,
            velocityRange: 70,
            yAcceleration: -64,
            emitAngle: 0.0,
            emitAngleRange: Float.pi * 2,
            emitterPosition: .zero,
            emitterSize: 8,
            color: .zero,
            duration: .zero,
            beginTime: 0.0
        )
        emitter.sizeAttenFactor = 1.0
        emitter.brightnessAttenFactor = 1.0
        return emitter
    }

    var tailEmitter: EmitterControl {
        var emitter = EmitterControl(
            birthRate: 256,
            lifetime: 0.5,
            velocity: 100,
            velocityRange: 80,
            yAcceleration: -350,
            emitAngle: 0.0,
            emitAngleRange: Float.pi * 2,
            emitterPosition: .zero,
            emitterSize: 4.0,
            color: .zero,
            duration: .zero,
            beginTime: 0.1
        )
        emitter.brightnessAttenFactor = 0.4
        emitter.sizeAttenFactor = 0.4
        return emitter
    }

    private func commonInit() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create Metal device")
        }
        self.device = device

        wantsLayer = true
        metalLayer.device = device
        metalLayer.framebufferOnly = true
        metalLayer.isOpaque = false
        metalLayer.wantsExtendedDynamicRangeContent = true
        metalLayer.pixelFormat = .rgba16Float
        metalLayer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
        layer?.addSublayer(metalLayer)

        renderer.setup(device)
        dummyMTKView = MTKView(frame: .zero, device: device)
        dummyMTKView.preferredFramesPerSecond = 60
        addSubview(dummyMTKView)
        dummyMTKView.delegate = renderer
        renderer.targetLayer = metalLayer
    }

    private static func randomLinearDisplayP3Color() -> simd_float4 {
        let color = displayP3Colors.randomElement() ?? displayP3Colors[0]
        return .init(
            linearized(color.x),
            linearized(color.y),
            linearized(color.z),
            1
        )
    }

    private static func linearized(_ component: Float) -> Float {
        if component <= 0.04045 {
            return component / 12.92
        }
        return pow((component + 0.055) / 1.055, 2.4)
    }

    func launchFireWork(
        atLocation: CGPoint? = nil,
        message: String? = nil,
        completion: (() -> Void)?
    ) {
        assert(Thread.isMainThread)
        layoutSubtreeIfNeeded()
        guard isPrepared, bounds.width > 0, bounds.height > 0 else {
            completion?()
            return
        }
        updateMetalLayerGeometry()

        var rootEmitter = rootEmitter
        if let atLocation {
            if abs(0 - atLocation.x) < 100 {
                rootEmitter.emitAngle = -Float.pi * 0.25
                rootEmitter.velocity /= 1.5
            }
            if abs(bounds.width - atLocation.x) < 100 {
                rootEmitter.emitAngle = Float.pi * 1.25
                rootEmitter.velocity /= 1.5
            }
            rootEmitter.emitterPosition = .init(
                x: Float(atLocation.x),
                y: Float(bounds.height - atLocation.y)
            )
        }
        rootEmitter.birthOnceMark = EmitterControl.BIRTH_ONCE
        let fireworkEmitter = fireworkEmitter
        let tailEmitter = tailEmitter
        var particles = [EmitterControl]()
        rootEmitter.nextEmitters = [fireworkEmitter]
        rootEmitter.tailEmitters = [tailEmitter]
        particles.append(rootEmitter)
        if let message, !message.isEmpty {
            renderer.onBurst = { [weak self] position in
                DispatchQueue.main.async { [weak self] in
                    self?.showCelebration(message, centeredAt: position)
                }
            }
        } else {
            renderer.onBurst = nil
        }
        renderer.addEmitters(particles: particles)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            completion?()
        }
    }

    private func showCelebration(_ message: String, centeredAt burstPosition: simd_float2) {
        let margin: CGFloat = 40
        let availableWidth = max(0, bounds.width - margin * 2)
        let availableHeight = max(0, bounds.height - margin * 2)
        guard availableWidth > 0, availableHeight > 0 else { return }

        let center = CGPoint(
            x: CGFloat(burstPosition.x),
            y: bounds.height - CGFloat(burstPosition.y)
        )
        let width = min(800, availableWidth)
        let height = min(160, availableHeight)
        let maximumX = max(margin, bounds.width - width - margin)
        let maximumY = max(margin, bounds.height - height - margin)
        let originX = min(max(margin, center.x - width / 2), maximumX)
        let originY = min(max(margin, center.y - height / 2), maximumY)
        let hostingView = NSHostingView(rootView: CelebrationBurstView(text: message))
        hostingView.frame = .init(x: originX, y: originY, width: width, height: height)
        addSubview(hostingView)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            hostingView.removeFromSuperview()
        }
    }

    func fadeOut(completion: (() -> Void)?) {
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1.0
        fadeOutAnimation.toValue = 0.0
        fadeOutAnimation.duration = 1.0
        fadeOutAnimation.isRemovedOnCompletion = true
        layer?.add(fadeOutAnimation, forKey: "opacity")
        layer?.opacity = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion?()
        }
    }
}
