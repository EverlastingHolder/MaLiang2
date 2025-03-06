//
//  MLLine.swift
//  MaLiang
//
//  Created by Harley.xk on 2018/4/12.
//

import Foundation
import Metal
import UIKit

/// a line strip with lines and brush info
open class LineStrip: CanvasElement {
    
    /// element index
    public var index: Int = 0
    
    /// identifier of bursh used to render this line strip
    public var brushName: String?
    
    /// default color
    // this color will be used when line's color not set
    public var color: MLColor
    
    private var alpha: Float
    
    /// line units of this line strip, avoid change this value directly when drawing.
    public var lines: [MLLine] = []
    
    /// brush used to render this line strip
    open weak var brush: Brush? {
        didSet {
            brushName = brush?.name
        }
    }
    
    public init(lines: [MLLine], brush: Brush, isLoadingFromData: Bool) {
        self.lines = lines
        self.brush = brush
        self.brushName = brush.name
        self.color = brush.renderingColor
        self.alpha = brush.renderingColor.alpha
        remakBuffer(rotation: brush.rotation, isLoadingFromData: isLoadingFromData)
    }
    
    open func append(lines: [MLLine]) {
        self.lines.append(contentsOf: lines)
        vertexBuffer = nil
    }
    
    public func drawSelf(on target: RenderTarget?, isLoadingFromData: Bool) {
        brush?.render(lineStrip: self, on: target, isLoadingFromData: isLoadingFromData)
    }
    
    /// get vertex buffer for this line strip, remake if not exists
    open func retrieveBuffers(rotation: Brush.Rotation, isLoadingFromData: Bool) -> MTLBuffer? {
        if vertexBuffer == nil {
            remakBuffer(rotation: rotation, isLoadingFromData: isLoadingFromData)
        }
        return vertexBuffer
    }
    
    /// count of vertexes, set when remake buffers
    open private(set) var vertexCount: Int = 0
    
    private var vertexBuffer: MTLBuffer?
    
    private func remakBuffer(rotation: Brush.Rotation, isLoadingFromData: Bool) {
        
        guard !lines.isEmpty else {
            return
        }
        
        var vertexes: [Point] = []
        
        lines.forEach { (line) in
            let scale = brush?.target?.contentScaleFactor ?? UIScreen.main.nativeScale
            let count = max(line.length / line.pointStep, 1)
            
            var line = line
            line.begin *= scale
            line.end *= scale

            // fix opacity of line color
            let overlapping = max(1, line.pointSize / line.pointStep)
            var renderingColor = color
            if !isLoadingFromData {
                renderingColor.alpha = renderingColor.alpha / Float(overlapping) * 2.5
            }
            alpha = renderingColor.alpha
//            print("current alpha: \(renderingColor.alpha), overlapping: \(overlapping), real alpha: \(color.alpha)")
            
            for index in 0 ..< Int(count) {
                let index = CGFloat(index)
                let x = line.begin.x + (line.end.x - line.begin.x) * (index / count)
                let y = line.begin.y + (line.end.y - line.begin.y) * (index / count)
                
                var angle: CGFloat = 0
                switch rotation {
                case let .fixed(arc): angle = arc
                case .random: angle = CGFloat.random(in: -CGFloat.pi ... CGFloat.pi)
                case .ahead: angle = line.angle
                }
                vertexes.append(Point(x: x, y: y,
                                      color: renderingColor,
                                      size: line.pointSize * scale,
                                      angle: angle,
                                      intensity: brush?.opacity ?? 0))
            }
        }
        
        vertexCount = vertexes.count
        vertexBuffer = sharedDevice?.makeBuffer(
            bytes: vertexes,
            length: MemoryLayout<Point>.stride * vertexCount,
            options: .cpuCacheModeWriteCombined
        )
    }
    
    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case index
        case brush
        case lines
        case color
        case alpha
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        brushName = try container.decode(String.self, forKey: .brush)
        lines = try container.decode([MLLine].self, forKey: .lines)
        alpha = try container.decode(Float.self, forKey: .alpha)
        color = try container.decode(MLColor.self, forKey: .color)
        color.alpha = alpha
    }
    
    public func encode(to encoder: Encoder) throws {
        if color.alpha > 1 {
            color.alpha = 1
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(brushName, forKey: .brush)
        try container.encode(lines, forKey: .lines)
        try container.encode(color, forKey: .color)
        try container.encode(alpha, forKey: .alpha)
    }
}
