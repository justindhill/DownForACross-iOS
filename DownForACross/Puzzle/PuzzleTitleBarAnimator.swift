//
//  PuzzleTitleBarAnimator.swift
//  DownForACross
//
//  Created by Justin Hill on 3/8/24.
//

import UIKit

class PuzzleTitleBarAnimator {
    
    enum Icon {
        case pencil
        case spinner
        case success
        
        fileprivate var image: UIImage {
            switch self {
                case .pencil: return UIImage(systemName: "pencil")!
                case .spinner: return UIImage(systemName: "circle.hexagonpath")!
                case .success: return UIImage(systemName: "checkmark.circle.fill")!
            }
        }
    }
    
    static let timeUntilDismiss: TimeInterval = 1
    let transitionDuration: TimeInterval = 0.2
    let navigationBar: UINavigationBar
    let navigationItem: UINavigationItem
    
    var _titleControl: UIView?
    var titleControl: UIView? {
        if let _titleControl {
            return _titleControl
        } else {
            self._titleControl = self.navigationBar.titleControl
            return self._titleControl
        }
    }

    
    private var hideTimer: Timer?
    
    let statusPill: UIButton = {
        let button = UIButton(configuration: .gray())
        button.configuration?.cornerStyle = .capsule
        button.configuration?.imagePadding = 4
        button.isUserInteractionEnabled = false
        button.titleLabel?.tintColor = .label
        
        return button
    }()
    
    init(navigationBar: UINavigationBar, navigationItem: UINavigationItem) {
        self.navigationBar = navigationBar
        self.navigationItem = navigationItem
    }
    
    func showPill(withText text: String, timeout: TimeInterval? = PuzzleTitleBarAnimator.timeUntilDismiss, icon: Icon, animated: Bool = true) {
        self.statusPill.configuration?.title = text
        self.statusPill.configuration?.image = icon.image
        self.statusPill.sizeToFit() // inexplicably makes the button tall for some texts
        self.statusPill.frame.size.height = 0 // UINavigationController fixes the height after doing this
        
        if let hideTimer = self.hideTimer {
            hideTimer.invalidate()
            self.hideTimer = nil
        }
        
        self.setStatusPillVisible(true, animated: animated)
        
        let spinAnimationKey = "spin"
        if icon == .spinner {
            if self.statusPill.imageView?.layer.animation(forKey: spinAnimationKey) == nil {
                let spinAnimation = CABasicAnimation(keyPath: "transform")
                spinAnimation.fromValue = CATransform3DMakeAffineTransform(CGAffineTransformIdentity)
                spinAnimation.toValue = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 3))
                spinAnimation.duration = 0.4
                spinAnimation.repeatCount = .infinity
                spinAnimation.repeatDuration = .infinity
                self.statusPill.imageView?.layer.add(spinAnimation, forKey: spinAnimationKey)
            }
        } else {
            self.statusPill.imageView?.layer.removeAnimation(forKey: spinAnimationKey)
        }
        
        if let timeout {
            self.hideTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] _ in
                guard let self else { return }
                self.hideTimer = nil
                self.setStatusPillVisible(false, animated: true)
            })
        }
    }
    
    private func setStatusPillVisible(_ visible: Bool, animated: Bool) {
        let needsUpdate = (visible && self.navigationItem.titleView == nil) ||
                          (!visible && self.navigationItem.titleView != nil)
        
        if !needsUpdate {
            return
        }
        
        CATransaction.begin()
        
        let transition = CATransition()
        transition.duration = self.transitionDuration
        transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        if visible {
            transition.type = .moveIn
            transition.subtype = .fromBottom
            self.navigationItem.titleView = self.statusPill
        } else {
            transition.type = .reveal
            transition.subtype = .fromTop
            self.navigationItem.titleView = nil
        }
        
        if animated {
            self.titleControl?.layer.add(transition, forKey: nil)
        }

        CATransaction.commit()
    }
    
}
