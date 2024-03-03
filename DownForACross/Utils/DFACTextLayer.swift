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
        
        let yDiff = (self.bounds.size.height - font.lineHeight) / 2

        context.saveGState()
        context.translateBy(x: 0, y: yDiff)
        super.draw(in: context)
        context.restoreGState()
    }
    
}
