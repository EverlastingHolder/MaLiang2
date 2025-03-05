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
    
    open var maskTexture: MTLTexture?
    
    /// Переопределение метода шейдеров для кисти
    open override func makeShaderFragmentFunction(from library: MTLLibrary) -> MTLFunction? {
        // Используем пользовательский фрагментный шейдер для проявления маски
        return library.makeFunction(name: "fragment_mask_func")
    }
    
    /// Настройка параметров смешивания для эффекта растушевки
    open override func setupBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        
        attachment.sourceRGBBlendFactor = .sourceAlpha
        attachment.sourceAlphaBlendFactor = .one
        
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
    open override func render(lineStrip: LineStrip, on renderTarget: RenderTarget? = nil, isLoadingFromData: Bool) {
        
        let renderTarget = renderTarget ?? target?.screenTarget
        
        guard !lineStrip.lines.isEmpty, let target = renderTarget else {
            return
        }
        
        /// make sure reusable command buffer is ready
        target.prepareForDraw()
        
        /// get commandEncoder form resuable command buffer
        let commandEncoder = target.makeCommandEncoder(rpd: target.renderPassDescriptor)
        
        commandEncoder?.setRenderPipelineState(pipelineState)
        
        if let vertexBuffer = lineStrip.retrieveBuffers(rotation: rotation, isLoadingFromData: isLoadingFromData) {
            commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder?.setVertexBuffer(target.uniformBuffer, offset: 0, index: 1)
            commandEncoder?.setVertexBuffer(target.transformBuffer, offset: 0, index: 2)
            if let mask = maskTexture {
                commandEncoder?.setFragmentTexture(mask, index: 0)
            }
            if let canvas = target.texture {
                commandEncoder?.setFragmentTexture(canvas, index: 1)
            }
            commandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: lineStrip.vertexCount)
        }
        
        commandEncoder?.endEncoding()
    }
}
