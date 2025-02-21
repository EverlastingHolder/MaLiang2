//
//  Eraser.swift
//  MaLiang_Example
//
//  Created by Harley-xk on 2019/4/7.
//  Copyright © 2019 Harley-xk. All rights reserved.
//

import Foundation
import UIKit
import Metal

open class Eraser: Brush {
    
    open override func setupBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        attachment.alphaBlendOperation = .reverseSubtract
        attachment.rgbBlendOperation = .reverseSubtract
        attachment.sourceRGBBlendFactor = .zero
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .one
    }
    
    override func render(lineStrip: LineStrip, on renderTarget: RenderTarget? = nil) {
        let renderTarget = renderTarget ?? target?.screenTarget
        
        guard lineStrip.lines.count > 0, let target = renderTarget else {
            return
        }
        
        /// make sure reusable command buffer is ready
        target.prepareForDraw()
        
        /// get commandEncoder form resuable command buffer
        let commandEncoder = target.makeCommandEncoder(rpd: target.renderPassDescriptor)
        
        commandEncoder?.setRenderPipelineState(pipelineState)
        
        if let vertex_buffer = lineStrip.retrieveBuffers(rotation: rotation) {
            commandEncoder?.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
            commandEncoder?.setVertexBuffer(target.uniformBuffer, offset: 0, index: 1)
            commandEncoder?.setVertexBuffer(target.transformBuffer, offset: 0, index: 2)
            if let texture = texture {
                commandEncoder?.setFragmentTexture(texture, index: 0)
            }
            commandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: lineStrip.vertexCount)
        }
        
        commandEncoder?.endEncoding()
        
        let commandEncoder2 = target.makeCommandEncoder(rpd: target.maskRenderPassDescriptor)
        
        commandEncoder2?.setRenderPipelineState(pipelineState)
        
        if let vertex_buffer = lineStrip.retrieveBuffers(rotation: rotation) {
            commandEncoder2?.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
            commandEncoder2?.setVertexBuffer(target.uniformBuffer, offset: 0, index: 1)
            commandEncoder2?.setVertexBuffer(target.transformBuffer, offset: 0, index: 2)
            if let texture = texture {
                commandEncoder2?.setFragmentTexture(texture, index: 0)
            }
            commandEncoder2?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: lineStrip.vertexCount)
        }
        
        commandEncoder2?.endEncoding()
    }
}
