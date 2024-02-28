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
    
    let subviewLayoutMargins: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    enum Tab: Int {
        case clues
        case messages
        case players
    }
    
    var currentTab: Tab {
        get {
            if self.segmentedControl.selectedSegmentIndex == Tab.clues.rawValue {
                return .clues
            } else if self.segmentedControl.selectedSegmentIndex == Tab.players.rawValue {
                return .players
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
    let playersViewController: PuzzlePlayersViewController
    
    let segmentedControl = UISegmentedControl(items: [
        UIImage(systemName: "list.bullet.rectangle")!,
        UIImage(systemName: "message")!,
        UIImage(systemName: "person.2")!
    ])
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(puzzle: Puzzle) {
        self.clueListViewController = PuzzleClueListViewController(clues: puzzle.clues)
        self.messagesViewController = PuzzleMessagesViewController()
        self.playersViewController = PuzzlePlayersViewController()
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
        self.clueListViewController.viewRespectsSystemMinimumLayoutMargins = false
        self.clueListViewController.view.layoutMargins = self.subviewLayoutMargins
        self.clueListViewController.didMove(toParent: self)
        
        self.messagesViewController.willMove(toParent: self)
        self.addChild(self.messagesViewController)
        self.messagesViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.messagesViewController.view)
        self.messagesViewController.viewRespectsSystemMinimumLayoutMargins = false
        self.messagesViewController.view.layoutMargins = self.subviewLayoutMargins
        self.messagesViewController.didMove(toParent: self)
        self.messagesViewController.view.layer.opacity = 0
        self.messagesViewController.view.isHidden = true
        
        self.playersViewController.willMove(toParent: self)
        self.addChild(self.playersViewController)
        self.playersViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.playersViewController.view)
        self.playersViewController.viewRespectsSystemMinimumLayoutMargins = false
        self.playersViewController.view.layoutMargins = self.subviewLayoutMargins
        self.playersViewController.didMove(toParent: self)
        self.playersViewController.view.layer.opacity = 0
        self.playersViewController.view.isHidden = true
        
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
            self.messagesViewController.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.playersViewController.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.playersViewController.view.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: 8),
            self.playersViewController.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.playersViewController.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
    
    @objc func selectedSegmentDidChange(_ sender: UISegmentedControl) {
        switch self.currentTab {
            case .clues:
                ShowHideAnimationHelpers.show(view: self.clueListViewController.view)
                ShowHideAnimationHelpers.hide(view: self.messagesViewController.view)
                ShowHideAnimationHelpers.hide(view: self.playersViewController.view)
                self.delegate?.sideBarViewController(self, didSwitchToTab: .clues)
            case .messages:
                ShowHideAnimationHelpers.show(view: self.messagesViewController.view)
                ShowHideAnimationHelpers.hide(view: self.clueListViewController.view)
                ShowHideAnimationHelpers.hide(view: self.playersViewController.view)
                self.delegate?.sideBarViewController(self, didSwitchToTab: .messages)
            case .players:
                ShowHideAnimationHelpers.hide(view: self.clueListViewController.view)
                ShowHideAnimationHelpers.hide(view: self.messagesViewController.view)
                ShowHideAnimationHelpers.show(view: self.playersViewController.view)
                self.delegate?.sideBarViewController(self, didSwitchToTab: .players)
        }
    }
    
}
