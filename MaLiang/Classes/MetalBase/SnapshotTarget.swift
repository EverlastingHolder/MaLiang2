//
//  SnapshotTarget.swift
//  MaLiang
//
//  Created by Harley-xk on 2019/4/18.
//

import Foundation
import UIKit

/// Snapshoting Target, used for snapshot
open class SnapshotTarget: RenderTarget {
    
    private weak var canvas: MLCanvas?

    /// create target specified with a canvas
    public init(canvas: MLCanvas) {
        self.canvas = canvas
        var size = canvas.bounds.size
        if let scrollable = canvas as? ScrollableCanvas {
            size = scrollable.contentSize * scrollable.contentScaleFactor
        }
        super.init(size: size, pixelFormat: canvas.colorPixelFormat, device: canvas.device)
    }
    
    /// get UIImage from canvas content
    ///
    /// - Returns: UIImage, nil if failed
    open func getImage() -> UIImage? {
        syncContent()
        return texture?.toUIImage()
    }
    
    /// get CIImage from canvas content
    open func getCIImage() -> CIImage? {
        syncContent()
        return texture?.toCIImage()
    }
    
    /// get CGImage from canvas content
    open func getCGImage() -> CGImage? {
        syncContent()
        return texture?.toCGImage()
    }

    /// get UIImage of single CanvasElement
    open func getImage(canvasElement: CanvasElement) -> UIImage? {
        syncContent(canvasElement: canvasElement)
        return texture?.toUIImage()
    }

    /// get CIImage of single CanvasElement
       open func getCIImage(canvasElement: CanvasElement) -> CIImage? {
           syncContent(canvasElement: canvasElement)
           return texture?.toCIImage()
       }

    /// get CGImage of single CanvasElement
       open func getCGImage(canvasElement: CanvasElement) -> CGImage? {
           syncContent(canvasElement: canvasElement)
           return texture?.toCGImage()
       }

    private func syncContent(canvasElement: CanvasElement? = nil) {
        if let canvasElement = canvasElement {
            let scale = canvas?.contentScaleFactor ?? 1
            updateBuffer(with: CGSize(width: drawableSize.width * scale, height: drawableSize.height * scale))
            prepareForDraw()
            clear()
            canvasElement.drawSelf(on: self, isLoadingFromData: false)
        } else {
            canvas?.redraw(on: self, isLoadingFromData: false)
        }
        commitCommands()
    }
}
