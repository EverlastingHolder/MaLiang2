//
//  MaskBrush.swift
//  MaLiang
//
//  Created by roman.moshkovcev on 17.02.2025.
//  Copyright © 2025 MoveApp. All rights reserved.
//

import Foundation
import MetalKit

open class MaskBrush: Brush {
    
    /// Переопределение метода шейдеров для кисти
    open override func makeShaderFragmentFunction(from library: MTLLibrary) -> MTLFunction? {
        // Используем пользовательский фрагментный шейдер для растушевки
        return library.makeFunction(name: "fragment_mask_func")
    }
    
    /// Настройка параметров смешивания для эффекта растушевки
    open override func setupBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        
        attachment.sourceRGBBlendFactor = .sourceAlpha
        attachment.sourceAlphaBlendFactor = .sourceAlpha
        
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
    open override func render(lineStrip: LineStrip, on renderTarget: RenderTarget? = nil) {
        
        let renderTarget = renderTarget ?? target?.screenTarget
        
        guard !lineStrip.lines.isEmpty, let target = renderTarget else {
            return
        }
        
        /// make sure reusable command buffer is ready
        target.prepareForDraw()
        
        /// get commandEncoder form resuable command buffer
        let commandEncoder = target.makeCommandEncoder()
        
        commandEncoder?.setRenderPipelineState(pipelineState)
        
        if let vertexBuffer = lineStrip.retrieveBuffers(rotation: rotation) {
            commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder?.setVertexBuffer(target.uniformBuffer, offset: 0, index: 1)
            commandEncoder?.setVertexBuffer(target.transformBuffer, offset: 0, index: 2)
            if let texture = texture {
                commandEncoder?.setFragmentTexture(texture, index: 0)
            }
            if let texture = renderTarget?.texture {
                commandEncoder?.setFragmentTexture(texture, index: 1)
            }
            commandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: lineStrip.vertexCount)
        }
        
        commandEncoder?.endEncoding()
    }
}
