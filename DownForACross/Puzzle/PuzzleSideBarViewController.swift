//
//  PuzzleSideBarViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 1/31/24.
//

import UIKit

class PuzzleSideBarViewController: UIViewController {
    
    enum Tab: Int {
        case clues
        case messages
    }
    
    let clueListViewController: PuzzleClueListViewController
    let messagesViewController: PuzzleMessagesViewController
    
    let segmentedControl = UISegmentedControl(items: [
        UIImage(systemName: "list.bullet.rectangle")!,
        UIImage(systemName: "message")!
    ])
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(puzzle: Puzzle) {
        self.clueListViewController = PuzzleClueListViewController(clues: puzzle.clues)
        self.messagesViewController = PuzzleMessagesViewController()
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    }
    
    var contentView: UIView {
        let view = self.view as! UIVisualEffectView
        return view.contentView
    }
    
    override func viewDidLoad() {
        self.contentView.addSubview(self.segmentedControl)
        
        self.clueListViewController.willMove(toParent: self)
        self.addChild(self.clueListViewController)
        self.clueListViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.clueListViewController.view)
        self.clueListViewController.didMove(toParent: self)
        
        self.messagesViewController.willMove(toParent: self)
        self.addChild(self.messagesViewController)
        self.messagesViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.messagesViewController.view)
        self.messagesViewController.didMove(toParent: self)
        self.messagesViewController.view.layer.opacity = 0
        
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControl.addTarget(self, action: #selector(selectedSegmentDidChange(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            self.segmentedControl.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.segmentedControl.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.segmentedControl.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.clueListViewController.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.clueListViewController.view.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: 8),
            self.clueListViewController.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.clueListViewController.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.messagesViewController.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.messagesViewController.view.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: 8),
            self.messagesViewController.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.messagesViewController.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
    
    @objc func selectedSegmentDidChange(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == Tab.clues.rawValue {
            self.show(view: self.clueListViewController.view)
            self.hide(view: self.messagesViewController.view)
        } else {
            self.show(view: self.messagesViewController.view)
            self.hide(view: self.clueListViewController.view)
        }
    }
    
    func hide(view: UIView) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            view.isHidden = true
            view.layer.removeAllAnimations()
        }

        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 1.0
        alphaAnimation.toValue = 0.0
        alphaAnimation.duration = 0.2
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = CATransform3DIdentity
        scaleAnimation.toValue = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 0.8, y: 0.8))
        scaleAnimation.duration = 0.2
        
        let group = CAAnimationGroup()
        group.animations = [alphaAnimation, scaleAnimation]
        group.duration = 0.2
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false

        view.layer.add(group, forKey: "outGroup")
        
        CATransaction.commit()
    }
    
    func show(view: UIView) {
        view.isHidden = false
        view.layer.opacity = 0
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            view.layer.opacity = 1
        }
        
        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 0.0
        alphaAnimation.toValue = 1.0
        alphaAnimation.duration = 0.2
        alphaAnimation.beginTime = 0.1
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 0.8, y: 0.8))
        scaleAnimation.toValue = CATransform3DIdentity
        scaleAnimation.duration = 0.2
        scaleAnimation.beginTime = 0.1
        
        let group = CAAnimationGroup()
        group.animations = [alphaAnimation, scaleAnimation]
        group.duration = 0.3
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.isRemovedOnCompletion = true

        view.layer.add(group, forKey: "inGroup")
        
        CATransaction.commit()

    }
    
}
