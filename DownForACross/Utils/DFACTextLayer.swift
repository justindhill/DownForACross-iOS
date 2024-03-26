//
//  DFACTextLayer.swift
//  DownForACross
//
//  Created by Justin Hill on 3/2/24.
//

import UIKit

class DFACTextLayer: CATextLayer {
    
    static var incorrectSlashPath: CGPath?
    static var incorrectSlashColor: CGColor?
    var drawsIncorrectSlash: Bool = false

    var textStrokeColor: CGColor?
    var textStrokeWidth: CGFloat = 2

    override func draw(in context: CGContext) {
        guard let font else {
            super.draw(in: context)
            return
        }

        if self.drawsIncorrectSlash, let path = DFACTextLayer.incorrectSlashPath, let color = DFACTextLayer.incorrectSlashColor {
            let slashLineWidth = (self.frame.size.width * 0.1)

            context.setStrokeColor(color)
            context.setLineWidth(slashLineWidth)
            context.addPath(path)
            context.strokePath()
        }

        let spaceSurroundingCaps = font.lineHeight - font.capHeight - font.descender
        let sideRatio = (font.lineHeight - font.capHeight) / -font.descender
        let yDiff = (self.frame.size.height - font.lineHeight) * (1 / sideRatio)

        context.saveGState()
        context.translateBy(x: 0, y: yDiff)

        if let textStrokeColor = self.textStrokeColor {
            context.saveGState()
            context.setLineWidth(self.textStrokeWidth)
            context.setStrokeColor(textStrokeColor)
            context.setTextDrawingMode(.stroke)
            super.draw(in: context)
            context.restoreGState()
        }

        context.setTextDrawingMode(.fill)
        super.draw(in: context)
        context.restoreGState()
    }
    
}
