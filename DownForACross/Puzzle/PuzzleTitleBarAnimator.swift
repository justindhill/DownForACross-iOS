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
        case circle(color: UIColor)
        case cancel

        fileprivate var image: UIImage {
            switch self {
                case .pencil: UIImage(systemName: "pencil")!
                case .spinner: UIImage(systemName: "circle.hexagonpath")!
                case .success: UIImage(systemName: "checkmark.circle.fill")!
                case .circle: UIImage(systemName: "circle.fill")!
                case .cancel: UIImage(systemName: "xmark.circle.fill")!
            }
        }
    }
    
    static let timeUntilDismiss: TimeInterval = 1.4
    static let frozenTime: TimeInterval = -1
    let transitionDuration: TimeInterval = 0.2
    let navigationBar: UINavigationBar
    let navigationItem: UINavigationItem
    private var frozenUntilCanceled: Bool = false
    private var dismissalBlock: (() -> Void)? = nil

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
    
    lazy var statusPill: UIButton = {
        let button = UIButton(configuration: .gray())
        button.configuration?.cornerStyle = .capsule
        button.configuration?.imagePadding = 4
        button.isUserInteractionEnabled = false
        button.titleLabel?.tintColor = .label
        button.addTarget(self, action: #selector(cancelIfPossible(_:)), for: .primaryActionTriggered)

        return button
    }()

    var title: NSAttributedString = NSAttributedString() {
        didSet {
            self.titleLabel.attributedText = self.title
            self.titleLabel.sizeToFit()
        }
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    init(navigationBar: UINavigationBar, navigationItem: UINavigationItem) {
        self.navigationBar = navigationBar
        self.navigationItem = navigationItem
    }
    
    func showPill(withText text: String, 
                  timeout: TimeInterval? = PuzzleTitleBarAnimator.timeUntilDismiss,
                  icon: Icon,
                  animated: Bool = true,
                  didDismiss: (() -> Void)? = nil) {
        if self.frozenUntilCanceled {
            return
        }

        self.statusPill.configuration?.title = text
        self.statusPill.configuration?.image = icon.image
        self.statusPill.sizeToFit() // inexplicably makes the button tall for some texts
        self.statusPill.frame.size.height = 0 // UINavigationController fixes the height after doing this

        self.dismissalBlock?()
        self.dismissalBlock = didDismiss

        self.hideTimer?.invalidate()
        self.hideTimer = nil
        
        self.setStatusPillVisible(true, animated: animated)
        
        let spinAnimationKey = "spin"
        switch icon {
            case .spinner:
                if self.statusPill.imageView?.layer.animation(forKey: spinAnimationKey) == nil {
                    let spinAnimation = CABasicAnimation(keyPath: "transform")
                    spinAnimation.fromValue = CATransform3DMakeAffineTransform(CGAffineTransformIdentity)
                    spinAnimation.toValue = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 3))
                    spinAnimation.duration = 0.4
                    spinAnimation.repeatCount = .infinity
                    spinAnimation.repeatDuration = .infinity
                    self.statusPill.imageView?.layer.add(spinAnimation, forKey: spinAnimationKey)
                }

            case .circle(let color):
                self.statusPill.imageView?.tintColor = color

            default:
                self.statusPill.imageView?.layer.removeAnimation(forKey: spinAnimationKey)
                self.statusPill.imageView?.tintColor = nil
        }

        self.statusPill.isUserInteractionEnabled = false
        if let timeout {
            if timeout == Self.frozenTime {
                self.frozenUntilCanceled = true
                self.statusPill.isUserInteractionEnabled = true
                return
            }
            self.hideTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] _ in
                guard let self else { return }
                self.hideTimer = nil
                self.setStatusPillVisible(false, animated: true)
            })
        }
    }

    @objc private func cancelIfPossible(_ sender: UIView) {
        if self.frozenUntilCanceled {
            self.frozenUntilCanceled = false
            self.dismissalBlock?()
            self.dismissalBlock = nil
            self.setStatusPillVisible(false, animated: true)
        }
    }

    private func setStatusPillVisible(_ visible: Bool, animated: Bool) {
        let needsUpdate = (visible && self.navigationItem.titleView != self.statusPill) ||
                          (!visible && self.navigationItem.titleView != self.titleLabel)

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
            self.navigationItem.titleView = self.titleLabel
        }
        
        if animated {
            self.titleControl?.layer.add(transition, forKey: nil)
        }

        CATransaction.commit()
    }
    
}
