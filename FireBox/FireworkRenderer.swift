//
//  FireworkRenderer.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import AppKit
import MetalKit

class FireworkRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!

    private struct GPUParticle {
        var position: simd_float2
        var velocity: simd_float2
        var yAcceleration: simd_float1
        var lifetime: simd_float1
        var leftTime: simd_float1 = .zero
        var elapsedTime: simd_float1 = .zero
        var startsize: simd_float1
        var brightnessAtten: simd_float1 = .zero
        var sizeAtten: simd_float1 = .zero
        var emitterId: simd_int1
        var particleId: simd_int1
        let pad0: simd_float3 = .zero
        var color: simd_float4
        var transform: simd_float4x4 = .init()
    }

    private struct Vertex {
        var position: simd_float4
        var uv: simd_float2
    }

    var targetLayer: CAMetalLayer?
    var isPrepared = false
    private var renderPipeline: MTLRenderPipelineState!
    private var computePipeline: MTLComputePipelineState!
    private var vertexBuffer: MTLBuffer!
    private var fireworkTexture: MTLTexture!
    private var elapsedTime = 0.0
    private var emitters: [EmitterControl] = []
    private var particleBuffer: MTLBuffer!
    private var particleCount: Int = 0
    private var targetFrameSize: simd_float2 = .zero
    private var commandQueue: MTLCommandQueue!
    private var lastTime: CFTimeInterval = -1.0
    private var particleIdAcc = 0

    func setup(_ device: MTLDevice, size: CGSize) {
        self.device = device
        makeRenderPipeline(device, size: size)
    }

    func makeRenderPipeline(_ device: MTLDevice, size: CGSize) {
        guard !isPrepared else {
            return
        }

        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to initialize Metal library")
        }

        let particleVertexFunction = library.makeFunction(name: "particleVertex")!
        let particleFragmentFunction = library.makeFunction(name: "particleFragment")!
        let updateParticlesFunction = library.makeFunction(name: "updateParticles")!

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.vertexFunction = particleVertexFunction
        renderPipelineDescriptor.fragmentFunction = particleFragmentFunction
        renderPipeline = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        computePipeline = try! device.makeComputePipelineState(function: updateParticlesFunction)

        let vertices: [Vertex] = [
            .init(position: .init(0, 0, 0, 1), uv: .init(0, 0)),
            .init(position: .init(1, 0, 0, 1), uv: .init(1, 0)),
            .init(position: .init(0, 1, 0, 1), uv: .init(0, 1)),
            .init(position: .init(1, 1, 0, 1), uv: .init(1, 1)),
        ]
        let vertexBuffer = vertices.withUnsafeBytes { pointer in
            device.makeBuffer(bytes: pointer.baseAddress!,
                              length: MemoryLayout<Vertex>.stride * vertices.count,
                              options: .storageModeManaged)
        }
        self.vertexBuffer = vertexBuffer!
        targetFrameSize = .init(Float(size.width), Float(size.height))
        commandQueue = device.makeCommandQueue()!
        particleCount = 0

        let textureLoader = MTKTextureLoader(device: device)
        fireworkTexture = try! textureLoader.newTexture(cgImage: coreSparkle)

        isPrepared = true
    }

    func resize(_ size: CGSize) {
        targetFrameSize = .init(Float(size.width), Float(size.height))
    }

    func addEmitters(particles: [EmitterControl]) {
        emitters.append(contentsOf: particles)
        isPrepared = true
    }

    private func particleSystemCheckBirth(deltaTime: Float, idx: Int) -> GPUParticle? {
        if emitters[idx].birthOnceMark == EmitterControl.BIRTH_ONCE_DONE { return nil }

        emitters[idx].elapsedTimeSinceLastBirth += deltaTime
        emitters[idx].elapsedTimeSinceLastBirth = max(
            0,
            emitters[idx].elapsedTimeSinceLastBirth
        )

        var doBirth = false
        if !doBirth, emitters[idx].birthOnceMark == EmitterControl.BIRTH_ONCE { // once mark
            doBirth = true
            emitters[idx].birthOnceMark = EmitterControl.BIRTH_ONCE_DONE
        }

        if !doBirth {
            let minimalDeltaTime = 1.0 / emitters[idx].birthRate
            doBirth = false
                || emitters[idx].elapsedTimeSinceLastBirth == 0
                || emitters[idx].elapsedTimeSinceLastBirth > minimalDeltaTime
        }

        guard doBirth else { return nil }
        emitters[idx].elapsedTimeSinceLastBirth = 0

        let emitter = emitters[idx]
        return createGPUParticle(emitter: emitter, emitterId: idx, parentParticle: nil)
    }

    func updateParticleSystem(_ deltaTime: Float) {
        var newLiveParticles: [GPUParticle] = emitters
            .indices
            .compactMap { particleSystemCheckBirth(deltaTime: deltaTime, idx: $0) }

        var previousParticles: [GPUParticle] = []
        if particleBuffer != nil, particleBuffer.length > 0 {
            let pointer = particleBuffer.contents().bindMemory(to: GPUParticle.self, capacity: particleCount)
            previousParticles = Array(UnsafeBufferPointer(start: pointer, count: particleCount))
        }

        // FIXME: Unexpected Particles Reborn
        previousParticles.indices.forEach { i in
            let gpuParticle = previousParticles[i]

            if gpuParticle.leftTime > 0 {
                newLiveParticles.append(gpuParticle)
                guard gpuParticle.emitterId != -1 else { return }
                let parentEmitter = emitters[Int(gpuParticle.emitterId)]
                guard let tailEmitters = parentEmitter.tailEmitters else { return }
                tailEmitters.forEach { emitter in
                    guard gpuParticle.elapsedTime > emitter.beginTime else { return }
                    previousParticles[i].elapsedTime = 0.0
                    let particle = createGPUParticle(emitter: emitter, emitterId: -1, parentParticle: gpuParticle)
                    newLiveParticles.append(particle)
                }
                return
            }

            if gpuParticle.emitterId != -1 {
                let parentEmitter = emitters[Int(gpuParticle.emitterId)]
                guard let nextEmitters = parentEmitter.nextEmitters else { return }
                nextEmitters.forEach { emitter in
                    for _ in 0 ..< Int(emitter.birthRate) {
                        var particle = createGPUParticle(emitter: emitter, emitterId: -1, parentParticle: gpuParticle)
                        particle.leftTime += deltaTime
                        newLiveParticles.append(particle)
                    }
                }
                return
            }
        }

        guard newLiveParticles.count > 0 else { return }
        particleBuffer = newLiveParticles.withUnsafeBytes { pointer in
            device.makeBuffer(
                bytes: pointer.baseAddress!,
                length: MemoryLayout<GPUParticle>.stride * newLiveParticles.count,
                options: .storageModeShared
            )
        }
        particleCount = newLiveParticles.count
    }

    private func createGPUParticle(emitter: EmitterControl, emitterId: Int, parentParticle: GPUParticle?) -> GPUParticle {
        var position = emitter.emitterPosition
        if let parent = parentParticle {
            position += parent.position
        }

        var speed = emitter.velocity
        if emitter.velocityRange > 0 {
            speed += Float.random(in: -emitter.velocityRange ... emitter.velocityRange)
        }
        var angle = emitter.emitAngle
        if emitter.emitAngleRange > 0 {
            angle += Float.random(in: -emitter.emitAngleRange ... emitter.emitAngleRange)
        }

        let velocity = simd_float2(speed * cos(angle), speed * sin(angle))
        let yAcceleration = emitter.yAcceleration
        let lifetime = emitter.lifetime
        let startsize = emitter.emitterSize
        var color = emitter.color
        if let parent = parentParticle {
            color += parent.color
        }
        func clamp<T: Comparable>(_ value: T, low: T, high: T) -> T {
            min(max(value, low), high)
        }
        if emitter.color_range.x > 0 {
            color.x = clamp(color.x + Float.random(in: -emitter.color_range.x ... emitter.color_range.x), low: 0.0, high: 2.0)
        }
        if emitter.color_range.y > 0 {
            color.y = clamp(color.y + Float.random(in: -emitter.color_range.y ... emitter.color_range.y), low: 0.0, high: 2.0)
        }
        if emitter.color_range.z > 0 {
            color.z = clamp(color.z + Float.random(in: -emitter.color_range.z ... emitter.color_range.z), low: 0.0, high: 2.0)
        }
        if emitter.color_range.w > 0 {
            color.w = clamp(color.w + Float.random(in: -emitter.color_range.w ... emitter.color_range.w), low: 0.0, high: 1.0)
        }
        let brightnessAtten = emitter.brightnessAttenFactor
        let sizeAtten = emitter.sizeAttenFactor

        let particleId = particleIdAcc
        particleIdAcc += 1
        let transform = simd_float4x4(diagonal: SIMD4<Float>(startsize, startsize, startsize, 1))
        return GPUParticle(
            position: position,
            velocity: velocity,
            yAcceleration: yAcceleration,
            lifetime: lifetime,
            leftTime: lifetime,
            startsize: startsize,
            brightnessAtten: brightnessAtten,
            sizeAtten: sizeAtten,
            emitterId: .init(emitterId),
            particleId: .init(particleId),
            color: color,
            transform: transform
        )
    }

    func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {
        // Since the view is not subject to resize, this will leave no-op.
    }

    func draw(in _: MTKView) {
        guard isPrepared else { return }

        guard let drawable = targetLayer?.nextDrawable() else { return }
        guard let targetLayer else { return }
        if lastTime < 0 {
            lastTime = CACurrentMediaTime()
            return
        }

        let currentTime = CACurrentMediaTime()
        var deltaTime = simd_float1(currentTime - lastTime)
        lastTime = currentTime

        updateParticleSystem(deltaTime)
        guard particleCount > 0 else { return }

        let viewCGSize = targetLayer.frame.size
        var viewSize = simd_float2(Float(viewCGSize.width), Float(viewCGSize.height))

        let threadgroupSize = min(computePipeline.maxTotalThreadsPerThreadgroup, particleCount)
        let computeCommandBuffer = commandQueue.makeCommandBuffer()!

        let computeCommandEncoder = computeCommandBuffer.makeComputeCommandEncoder()!
        computeCommandEncoder.setComputePipelineState(computePipeline)
        computeCommandEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        withUnsafeBytes(of: &deltaTime) { pointer in
            let deltaTimeBuffer = device.makeBuffer(
                bytes: pointer.baseAddress!,
                length: MemoryLayout<simd_float1>.stride,
                options: .storageModeShared
            )
            computeCommandEncoder.setBuffer(deltaTimeBuffer, offset: 0, index: 1)
        }
        computeCommandEncoder.dispatchThreads(
            .init(
                width: particleCount,
                height: 1,
                depth: 1
            ),
            threadsPerThreadgroup: .init(
                width: threadgroupSize,
                height: 1,
                depth: 1
            )
        )
        computeCommandEncoder.endEncoding()
        computeCommandBuffer.commit()
        computeCommandBuffer.waitUntilCompleted()

        let renderCommandBuffer = commandQueue.makeCommandBuffer()!

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        let renderCommandEncoder = renderCommandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor
        )!
        renderCommandEncoder.setRenderPipelineState(renderPipeline)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        withUnsafeBytes(of: &viewSize) { pointer in
            renderCommandEncoder.setVertexBytes(
                pointer.baseAddress!,
                length: MemoryLayout<simd_float2>.size,
                index: 1
            )
        }
        renderCommandEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 2)
        withUnsafeBytes(of: &targetFrameSize) { pointer in
            renderCommandEncoder.setVertexBytes(
                pointer.baseAddress!,
                length: MemoryLayout<simd_float2>.size,
                index: 3
            )
        }
        renderCommandEncoder.setFragmentTexture(fireworkTexture, index: 0)
        renderCommandEncoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: 4,
            instanceCount: particleCount
        )
        renderCommandEncoder.endEncoding()

        renderCommandBuffer.present(drawable)
        renderCommandBuffer.commit()
    }
}
