//
//  FireworkView.swift
//  Firework
//
//  Created by Soulghost on 2024/2/7.
//

import Cocoa
import MetalKit
import simd

class FireworkView: NSView {
    private var dummyMTKView: MTKView!
    private var metalLayer = CAMetalLayer()
    private var device: MTLDevice!
    private var renderer = FireworkRenderer()
    private var hasSetup = false

    var isPrepared: Bool { hasSetup && renderer.isPrepared }

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
        guard frame.width > 0, frame.height > 0 else { return }
        metalLayer.frame = frame
        setupRendererIfNeeded()
    }

    private func setupRendererIfNeeded() {
        if hasSetup { return }
        hasSetup = true
        renderer.setup(device, size: metalLayer.frame.size)
    }

    var rootEmitter: EmitterControl {
        let viewSize = metalLayer.bounds.size
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
            color: .init(237 / 255, 180 / 255, 154 / 255, 1),
            color_range: .init(0.05, 0.05, 0.05, 0.1),
            duration: 1.0,
            beginTime: 0.0
        )
    }

    var fireworkEmitter: EmitterControl {
        var emitter = EmitterControl(
            birthRate: 512,
            lifetime: 3,
            velocity: 80,
            velocityRange: 180,
            yAcceleration: -64,
            emitAngle: 0.0,
            emitAngleRange: Float.pi * 2,
            emitterPosition: .zero,
            emitterSize: 8,
            color: .zero,
            color_range: .zero,
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
            color_range: .zero,
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
        metalLayer.colorspace = CGColorSpace(name: CGColorSpace.itur_2100_PQ)
        layer?.addSublayer(metalLayer)

        dummyMTKView = MTKView()
        addSubview(dummyMTKView)
        dummyMTKView.delegate = renderer
        renderer.targetLayer = metalLayer
    }

    func launchFireWork(atLocation: CGPoint? = nil, completion: (() -> Void)?) {
        assert(Thread.isMainThread)
        guard isPrepared else {
            completion?()
            return
        }

        var rootEmitter = rootEmitter
        if let atLocation {
            if abs(0 - atLocation.x) < 100 {
                rootEmitter.emitAngle = -Float.pi * 0.25
                rootEmitter.velocity /= 1.5
            }
            if abs(frame.width - atLocation.x) < 100 {
                rootEmitter.emitAngle = Float.pi * 1.25
                rootEmitter.velocity /= 1.5
            }
            rootEmitter.emitterPosition = .init(
                x: Float(atLocation.x),
                y: Float(frame.height - atLocation.y)
            )
        }
        rootEmitter.birthOnceMark = EmitterControl.BIRTH_ONCE
        let fireworkEmitter = fireworkEmitter
        let tailEmitter = tailEmitter
        var particles = [EmitterControl]()
        rootEmitter.nextEmitters = [fireworkEmitter]
        rootEmitter.tailEmitters = [tailEmitter]
        particles.append(rootEmitter)
        renderer.addEmitters(particles: particles)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            completion?()
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
