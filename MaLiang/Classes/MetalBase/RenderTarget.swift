//
//  RenderTarget.swift
//  MaLiang
//
//  Created by Harley-xk on 2019/4/15.
//

import Foundation
import Metal
import simd
import UIKit

/// a target for any thing that can be render on
open class RenderTarget {
    
    /// texture to render on
    public private(set) var texture: MTLTexture?
    
    public private(set) var maskTexture: MTLTexture?
    
    /// the scale level of view, all things scales
    open var scale: CGFloat = 1 {
        didSet {
            updateTransformBuffer()
        }
    }
    
    /// the zoom level of render target, only scale render target
    open var zoom: CGFloat = 1
    
    /// the offset of render target with zoomed size
    open var contentOffset: CGPoint = .zero {
        didSet {
            updateTransformBuffer()
        }
    }
    
    /// create with texture and device
    public init(size: CGSize, pixelFormat: MTLPixelFormat, device: MTLDevice?) {
        self.drawableSize = size
        self.pixelFormat = pixelFormat
        self.device = device
        self.texture = makeEmptyTexture(isMask: false)
        self.maskTexture = makeEmptyTexture(isMask: true)
        self.commandQueue = device?.makeCommandQueue()
        
        renderPassDescriptor = MTLRenderPassDescriptor()
        maskRenderPassDescriptor = MTLRenderPassDescriptor()
        let attachment = renderPassDescriptor?.colorAttachments[0]
        let maskAttachment = maskRenderPassDescriptor?.colorAttachments[0]
        attachment?.texture = texture
        attachment?.loadAction = .load
        attachment?.storeAction = .store
        maskAttachment?.texture = maskTexture
        maskAttachment?.loadAction = .load
        maskAttachment?.storeAction = .store
        
        updateBuffer(with: size)
    }
    
    /// clear the contents of texture
    open func clear() {
        texture = makeEmptyTexture(isMask: false)
        maskTexture = makeEmptyTexture(isMask: true)
        renderPassDescriptor?.colorAttachments[0].texture = texture
        maskRenderPassDescriptor?.colorAttachments[0].texture = maskTexture
        commitCommands()
    }
    
    internal var pixelFormat: MTLPixelFormat = .bgra8Unorm
    internal var drawableSize: CGSize
    internal var uniformBuffer: MTLBuffer!
    internal var transformBuffer: MTLBuffer!
    internal var renderPassDescriptor: MTLRenderPassDescriptor?
    internal var maskRenderPassDescriptor: MTLRenderPassDescriptor?
    internal var commandBuffer: MTLCommandBuffer?
    internal var commandQueue: MTLCommandQueue?
    internal var device: MTLDevice?
    
    internal func updateBuffer(with size: CGSize) {
        self.drawableSize = size
        let metrix = Matrix.identity
        let zoomUniform = 2 * Float(zoom / scale)
        metrix.scaling(x: zoomUniform / Float(size.width), y: -zoomUniform / Float(size.height), z: 1)
        metrix.translation(x: -1, y: 1, z: 0)
        uniformBuffer = device?.makeBuffer(bytes: metrix.matrix, length: MemoryLayout<Float>.size * 16, options: [])
        
        updateTransformBuffer()
    }
    
    internal func updateTransformBuffer() {
        let scaleFactor = UIScreen.main.nativeScale
        var transform = ScrollingTransform(offset: contentOffset * scaleFactor, scale: scale)
        transformBuffer = device?.makeBuffer(
            bytes: &transform,
            length: MemoryLayout<ScrollingTransform>.stride,
            options: []
        )
    }
    
    internal func prepareForDraw() {
        if commandBuffer == nil {
            commandBuffer = commandQueue?.makeCommandBuffer()
        }
    }
    
    internal func makeCommandEncoder(rpd: MTLRenderPassDescriptor?) -> MTLRenderCommandEncoder? {
        guard let commandBuffer = commandBuffer, let rpd = rpd else {
            return nil
        }
        return commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
    }
    
    internal func commitCommands() {
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        commandBuffer = nil
    }
    
    // make empty testure
    internal func makeEmptyTexture(isMask: Bool) -> MTLTexture? {
        guard drawableSize.width * drawableSize.height > 0 else {
            return nil
        }
        
        let id = (isMask ? "Mask" : "") + "EmptyTexture" + drawableSize.debugDescription
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: Int(drawableSize.width),
            height: Int(drawableSize.height),
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let texture = device?.makeTexture(descriptor: textureDescriptor)
        texture?.label = id
        return texture
    }
}
