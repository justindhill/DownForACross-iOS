//
//  DFACTextLayer.swift
//  DownForACross
//
//  Created by Justin Hill on 3/2/24.
//

import UIKit

class DFACTextLayer: CATextLayer {
    
    static var incorrectSlashPath: CGPath = CGPath(rect: .zero, transform: nil)
    static var incorrectSlashColor: CGColor?
    static var circlePath: CGPath = CGPath(rect: .zero, transform: nil)
    static var circleColor: CGColor?

    var drawsIncorrectSlash: Bool = false {
        didSet { self.setNeedsDisplay() }
    }

    var drawsCircle: Bool = false {
        didSet { self.setNeedsDisplay() }
    }

    var textStrokeColor: CGColor? {
        didSet { self.setNeedsDisplay() }
    }

    var textStrokeWidth: CGFloat = 2 {
        didSet { self.setNeedsDisplay() }
    }

    override func draw(in context: CGContext) {
        guard let font else {
            super.draw(in: context)
            return
        }

        if self.drawsCircle, let color = DFACTextLayer.circleColor {
            let lineWidth = (self.frame.size.width * 0.05)

            context.saveGState()

            context.setStrokeColor(color)
            context.setLineWidth(lineWidth)
            context.addPath(DFACTextLayer.circlePath)
            context.strokePath()

            context.restoreGState()

        }

        if self.drawsIncorrectSlash, let color = DFACTextLayer.incorrectSlashColor {
            let lineWidth = (self.frame.size.width * 0.1)
            let offset = lineWidth * 0.5

            context.saveGState()

            context.setStrokeColor(color)
            context.setLineWidth(lineWidth)
            context.addPath(DFACTextLayer.incorrectSlashPath)
            context.strokePath()

            context.restoreGState()
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
