//
//  DFACTextLayer.swift
//  DownForACross
//
//  Created by Justin Hill on 3/2/24.
//

import UIKit

class DFACTextLayer: CATextLayer {

    override func draw(in context: CGContext) {
        guard let font else {
            super.draw(in: context)
            return
        }
        
        let ascenderAdjustment = (font.lineHeight - font.capHeight + font.descender - font.leading)
        let yCenterOffset = (self.frame.size.height - font.capHeight) / 2
        let yDiff = yCenterOffset - ascenderAdjustment
        

        context.saveGState()
        context.translateBy(x: 0, y: yDiff)
        super.draw(in: context)
        context.restoreGState()
    }
    
}
