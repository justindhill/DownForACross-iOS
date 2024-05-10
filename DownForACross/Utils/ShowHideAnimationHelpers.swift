//
//  ShowHideAnimationHelpers.swift
//  DownForACross
//
//  Created by Justin Hill on 2/27/24.
//

import UIKit

class ShowHideAnimationHelpers {

    static let DefaultAnimationDuration: TimeInterval = 0.2

    static func hide(view: UIView,
                     duration: TimeInterval = ShowHideAnimationHelpers.DefaultAnimationDuration,
                     completion: (() -> Void)? = nil) {
        if view.isHidden {
            return
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            view.isHidden = true
            view.layer.removeAllAnimations()
            completion?()
        }

        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 1.0
        alphaAnimation.toValue = 0.0
        alphaAnimation.duration = duration
        alphaAnimation.fillMode = .forwards
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = CATransform3DIdentity
        scaleAnimation.toValue = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 0.8, y: 0.8))
        scaleAnimation.duration = duration
        scaleAnimation.fillMode = .forwards
        
        let group = CAAnimationGroup()
        group.animations = [alphaAnimation, scaleAnimation]
        group.duration = duration
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false

        view.layer.add(group, forKey: "ShowHideGroup")

        CATransaction.commit()
    }
    
    static func show(view: UIView,
                     duration: TimeInterval = ShowHideAnimationHelpers.DefaultAnimationDuration,
                     completion: (() -> Void)? = nil) {
        if !view.isHidden {
            return
        }
        
        view.isHidden = false
        view.layer.opacity = 0
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            view.layer.opacity = 1
            view.layer.removeAllAnimations()
            completion?()
        }
        
        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 0.0
        alphaAnimation.toValue = 1.0
        alphaAnimation.duration = duration
        alphaAnimation.fillMode = .forwards
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 0.8, y: 0.8))
        scaleAnimation.toValue = CATransform3DIdentity
        scaleAnimation.duration = duration
        scaleAnimation.fillMode = .forwards
        
        let group = CAAnimationGroup()
        group.animations = [alphaAnimation, scaleAnimation]
        group.duration = duration
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        
        view.layer.add(group, forKey: "ShowHideGroup")
        
        CATransaction.commit()
    }
}
