//
//  Maths.swift
//  MetalKitTest
//
//  Created by Harley-xk on 2019/3/29.
//  Copyright © 2019 Someone Co.,Ltd. All rights reserved.
//

import CoreGraphics
import Foundation
import simd

struct Vertex {
    var position: vector_float4
    var textCoord: vector_float2
    
    init(position: CGPoint, textCoord: CGPoint) {
        self.position = position.toFloat4()
        self.textCoord = textCoord.toFloat2()
    }
}

struct Point {
    var position: vector_float4
    var color: vector_float4
    var angle: Float
    var size: Float
    var intensity: Float

    init(x: CGFloat, y: CGFloat, color: MLColor, size: CGFloat, angle: CGFloat = 0, intensity: CGFloat = 0) {
        self.position = vector_float4(Float(x), Float(y), 0, 1)
        self.size = Float(size)
        self.color = color.toFloat4()
        self.angle = Float(angle)
        self.intensity = Float(intensity)
    }
}

struct ScrollingTransform {
    var offset: vector_float2
    var scale: Float
    
    init(offset: CGPoint, scale: CGFloat) {
        self.offset = vector_float2(Float(offset.x), Float(offset.y))
        self.scale = Float(scale)
    }
}

struct Uniforms {
    var scaleMatrix: [Float]
    
    init(scale: Float = 1, drawableSize: CGSize) {
        scaleMatrix = Matrix.identity.scaling(x: 0.5, y: 0.5, z: 1).matrix
    }
}

struct ColorBuffer {
    var color: SIMD4<Float>
    
    init(red: Float, green: Float, blue: Float, alpha: Float) {
        color = SIMD4(red, green, blue, alpha)
    }
}

class Matrix {
    
    private(set) var matrix: [Float]
    
    static var identity = Matrix()
    
    private init() {
        matrix = [1, 0, 0, 0,
             0, 1, 0, 0,
             0, 0, 1, 0,
             0, 0, 0, 1
        ]
    }
    
    @discardableResult
    func translation(x: Float, y: Float, z: Float) -> Matrix {
        matrix[12] = x
        matrix[13] = y
        matrix[14] = z
        return self
    }
    
    @discardableResult
    func scaling(x: Float, y: Float, z: Float) -> Matrix {
        matrix[0] = x
        matrix[5] = y
        matrix[10] = z
        return self
    }
}

// MARK: - Point Utils
extension CGPoint {
    
    static func middle(point1: CGPoint, point2: CGPoint) -> CGPoint {
        return CGPoint(x: (point1.x + point2.x) * 0.5, y: (point1.y + point2.y) * 0.5)
    }
    
    func distance(to other: CGPoint) -> CGFloat {
        let point = pow(x - other.x, 2) + pow(y - other.y, 2)
        return sqrt(point)
    }
    
    func angel(to other: CGPoint = .zero) -> CGFloat {
        let point = self - other
        if y == 0 {
            return x >= 0 ? 0 : CGFloat.pi
        }
        return -CGFloat(atan2f(Float(point.y), Float(point.x)))
    }
    
    func toFloat4(z: CGFloat = 0, width: CGFloat = 1) -> vector_float4 {
        return [Float(x), Float(y), Float(z), Float(width)]
    }
    
    func toFloat2() -> vector_float2 {
        return [Float(x), Float(y)]
    }
    
    func offsetedBy(x: CGFloat = 0, y: CGFloat = 0) -> CGPoint {
        var point = self
        point.x += x
        point.y += y
        return point
    }
    
    func rotatedBy(_ angle: CGFloat, anchor: CGPoint) -> CGPoint {
        let point = self - anchor
        let angle = Double(-angle)
        let x = Double(point.x)
        let y = Double(point.y)
        let rotateX = x * cos(angle) - y * sin(angle)
        let rotateY = x * sin(angle) + y * cos(angle)
        return CGPoint(x: CGFloat(rotateX), y: CGFloat(rotateY)) + anchor
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    static func *= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x *= rhs.x
        lhs.y *= rhs.y
    }
    
    static func *= (lhs: inout CGPoint, rhs: CGFloat) {
        lhs.x *= rhs
        lhs.y *= rhs
    }

    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
    
    static func - (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }
    
    static func * (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        return CGPoint(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
    }
    
    static func / (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        return CGPoint(x: lhs.x / rhs.width, y: lhs.y / rhs.height)
    }
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
}

extension Comparable {
    func valueBetween(min: Self, max: Self) -> Self {
        if self > max {
            return max
        } else if self < min {
            return min
        }
        return self
    }
}
