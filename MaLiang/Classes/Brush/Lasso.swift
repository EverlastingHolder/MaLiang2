//
//  Lasso.swift
//  
//
//  Created by luongvinh on 17/04/2022.
//

import UIKit

open class Lasso: Brush {
 
    open override func renderEnded(at pan: Pan, on canvas: MLCanvas) {
        super.renderEnded(at: pan, on: canvas)
        
        // fill polygon
        guard let lineStrip = canvas.data.currentElement as? LineStrip,
              lineStrip.lines.count > 0
        else { return }

        let lines = lineStrip.lines
        
        let shape = MLLassoLayer()
        shape.opacity = Float(opacity)
        shape.lineWidth = pointSize
        shape.lineJoin = CAShapeLayerLineJoin.miter
        shape.strokeColor = color.cgColor
        shape.fillColor = color.cgColor

        let path = UIBezierPath()
        path.move(to: lines.first!.begin)
        path.addLine(to: lines.first!.end)
        for i in 1 ..< lines.count {
            path.addLine(to: lines[i].begin)
            path.addLine(to: lines[i].end)
        }
        path.close()
        
        shape.path = path.cgPath
        
        canvas.layer.addSublayer(shape)
    }
    
}

class MLLassoLayer: CAShapeLayer {
    
}
