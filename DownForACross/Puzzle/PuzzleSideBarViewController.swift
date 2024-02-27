//
//  PuzzleSideBarViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 1/31/24.
//

import UIKit

protocol PuzzleSideBarViewControllerDelegate: AnyObject {
    func sideBarViewController(_ sideBarViewController: PuzzleSideBarViewController, didSwitchToTab: PuzzleSideBarViewController.Tab)
}

class PuzzleSideBarViewController: UIViewController {
    
    enum Tab: Int {
        case clues
        case messages
    }
    
    var currentTab: Tab {
        get {
            if self.segmentedControl.selectedSegmentIndex == Tab.clues.rawValue {
                return .clues
            } else {
                return .messages
            }
        }
        
        set {
            self.segmentedControl.selectedSegmentIndex = newValue.rawValue
        }
    }
    
    weak var delegate: PuzzleSideBarViewControllerDelegate?
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
        switch self.currentTab {
            case .clues:
                ShowHideAnimationHelpers.show(view: self.clueListViewController.view)
                ShowHideAnimationHelpers.hide(view: self.messagesViewController.view)
                self.delegate?.sideBarViewController(self, didSwitchToTab: .clues)
            case .messages:
                ShowHideAnimationHelpers.show(view: self.messagesViewController.view)
                ShowHideAnimationHelpers.hide(view: self.clueListViewController.view)
                self.delegate?.sideBarViewController(self, didSwitchToTab: .messages)
        }
    }
    
}
