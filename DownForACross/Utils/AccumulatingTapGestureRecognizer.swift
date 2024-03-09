//
//  AccumulatingTapGestureRecognizer.swift
//  DownForACross
//
//  Created by Justin Hill on 3/8/24.
//

import UIKit

// A tap gesture recognizer that only triggers if the maximum number of simultaneous touches
// received was exactly equal to the required number of touches.
class AccumulatingTapGestureRecognizer: UIGestureRecognizer {
        
    var numberOfTouchesRequired: Int = 1
    private var accumulatedTouches: Set<UITouch> = []
    private var currentTouches: Set<UITouch> = []
    
    var accumulatedNumberOfTouches: Int {
        return self.accumulatedTouches.count
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        self.accumulatedTouches.formUnion(touches)
        self.accumulatedTouches = self.accumulatedTouches.filter({ $0.phase != .ended })
        self.currentTouches.formUnion(touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.currentTouches.subtract(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        self.currentTouches.subtract(touches)
        if self.currentTouches.count == 0 {
            if accumulatedNumberOfTouches == self.numberOfTouchesRequired {
                self.state = .ended
            } else {
                self.state = .failed
            }
            
            self.accumulatedTouches = []
        }
    }
    
}
