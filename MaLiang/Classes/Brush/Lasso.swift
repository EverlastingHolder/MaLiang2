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
        
        // transform lines to fill lasso polygon
        guard let lineStrip = canvas.data.currentElement as? LineStrip,
              lineStrip.lines.count > 0
        else { return }
        
        let lines = lineStrip.lines
        let lineNumber = lines.count
        let halfLineNumber = lineNumber / 2
        var newLines: [MLLine] = []
        for i in 0 ..< halfLineNumber {
            let firstLine = lines[i]
            let secondLine = lines[lineNumber - i - 1]
            let firstNewLine = MLLine(
                begin: firstLine.begin,
                end: secondLine.begin,
                pointSize: firstLine.pointSize * 2.5,
                pointStep: 1,
                color: firstLine.color
            )
            let secondNewLine = MLLine(
                begin: firstLine.end,
                end: secondLine.end,
                pointSize: firstLine.pointSize * 2.5,
                pointStep: 1,
                color: firstLine.color
            )
            newLines.append(firstNewLine)
            newLines.append(secondNewLine)
        }
        
        super.render(lines: newLines, on: canvas)
    }
    
}
