//
//  EmitterControl.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import Foundation
import MetalKit

struct EmitterControl {
    static let BIRTH_ONCE: Float = 0x114514
    static let BIRTH_ONCE_DONE: Float = 0x1919810
    var birthOnceMark: simd_float1 = 0

    var birthRate: simd_float1
    var lifetime: simd_float1
    var velocity: simd_float1
    var velocityRange: simd_float1
    var yAcceleration: simd_float1
    var emitAngle: simd_float1
    var emitAngleRange: simd_float1
    var emitterPosition: simd_float2
    var emitterSize: simd_float1
    var color: simd_float4
    var color_range: simd_float4
    var duration: simd_float1
    var beginTime: simd_float1
    var sizeAttenFactor: simd_float1 = .zero
    var brightnessAttenFactor: simd_float1 = .zero
    var tailEmitters: [EmitterControl]?
    var nextEmitters: [EmitterControl]?

    // internal
    var elapsedTimeSinceLastBirth: simd_float1 = -65535
}
