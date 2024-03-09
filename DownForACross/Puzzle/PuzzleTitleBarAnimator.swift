//
//  PuzzleTitleBarAnimator.swift
//  DownForACross
//
//  Created by Justin Hill on 3/8/24.
//

import UIKit

class PuzzleTitleBarAnimator {
    
    let timeUntilDismiss: TimeInterval = 1
    let transitionDuration: TimeInterval = 0.2
    let navigationBar: UINavigationBar
    let titleControl: UIView?
    let navigationItem: UINavigationItem
    
    private var hideTimer: Timer?
    
    let statusPill: UIButton = {
        let button = UIButton(configuration: .gray())
        button.configuration?.cornerStyle = .capsule
        button.configuration?.image = UIImage(systemName: "pencil")
        button.configuration?.imagePadding = 4
        button.isUserInteractionEnabled = false
        button.titleLabel?.tintColor = .label
        
        return button
    }()
    
    init(navigationBar: UINavigationBar, navigationItem: UINavigationItem) {
        self.navigationBar = navigationBar
        self.titleControl = navigationBar.titleControl
        self.navigationItem = navigationItem
    }
    
    func showPill(withText text: String) {
        self.statusPill.configuration?.title = text
        self.statusPill.sizeToFit() // inexplicably makes the button tall for some texts
        self.statusPill.frame.size.height = 0 // UINavigationController fixes the height after doing this
        
        if let hideTimer = self.hideTimer {
            hideTimer.invalidate()
            self.hideTimer = nil
        } else {
            self.setStatusPillVisible(true)
        }
        
        self.hideTimer = Timer.scheduledTimer(withTimeInterval: self.timeUntilDismiss, repeats: false, block: { [weak self] _ in
            guard let self else { return }
            self.hideTimer = nil
            self.setStatusPillVisible(false)
        })
    }
    
    private func setStatusPillVisible(_ visible: Bool) {
        CATransaction.begin()
        
        let transition = CATransition()
        transition.duration = self.transitionDuration
        transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        if self.navigationItem.titleView == nil {
            transition.type = .moveIn
            transition.subtype = .fromBottom
            self.navigationItem.titleView = self.statusPill
        } else {
            transition.type = .reveal
            transition.subtype = .fromTop
            self.navigationItem.titleView = nil
        }
        
        self.titleControl?.layer.add(transition, forKey: nil)

        CATransaction.commit()
    }
    
}
