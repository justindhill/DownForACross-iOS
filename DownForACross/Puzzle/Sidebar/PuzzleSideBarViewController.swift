//
//  PuzzleSideBarViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 1/31/24.
//

import UIKit
import Combine

protocol PuzzleSideBarViewControllerDelegate: AnyObject {
    func sideBarViewController(_ sideBarViewController: PuzzleSideBarViewController, didSwitchToTab: PuzzleSideBarViewController.Tab)
}

class PuzzleSideBarViewController: UIViewController {
    
    static let subviewLayoutMargins: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    enum Tab: Int {
        case clues
        case players
        case messages

        var image: UIImage {
            switch self {
                case .clues: UIImage(systemName: "list.bullet.rectangle")!
                case .players: UIImage(systemName: "person.2")!
                case .messages: UIImage(systemName: "message")!
            }
        }

        var badgedImage: UIImage? {
            switch self {
                case .messages: UIImage(systemName: "message.badge",
                                        withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemRed, .label, .label]))!
                default: nil
            }
        }
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
    }

    weak var delegate: PuzzleSideBarViewControllerDelegate?
    let clueListViewController: PuzzleClueListViewController
    let messagesViewController: PuzzleMessagesViewController
    let playersViewController: PuzzlePlayersViewController
    var subscriptions: [AnyCancellable] = []

    let leadingSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator.withAlphaComponent(0.1)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 0.5)
        ])
        
        return view
    }()
    
    let topSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator.withAlphaComponent(0.1)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        return view
    }()
    
    let segmentedControl = UISegmentedControl(items: [
        Tab.clues.image,
        Tab.players.image,
        Tab.messages.image
    ])

    var gameClient: GameClient {
        didSet {
            self.playersViewController.gameClient = gameClient
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(puzzle: Puzzle, gameClient: GameClient, settingsStorage: SettingsStorage) {
        self.clueListViewController = PuzzleClueListViewController(clues: puzzle.clues)
        self.messagesViewController = PuzzleMessagesViewController(gameClient: gameClient, settingsStorage: settingsStorage)
        self.playersViewController = PuzzlePlayersViewController(gameClient: gameClient)
        self.gameClient = gameClient
        super.init(nibName: nil, bundle: nil)

        self.subscriptions.append(self.messagesViewController.$hasUnreadMessages.sink(receiveValue: { [weak self] hasUnreadMessages in
            guard let self else { return }
            if hasUnreadMessages {
                self.segmentedControl.setImage(Tab.messages.badgedImage, forSegmentAt: Tab.messages.rawValue)
            } else {
                self.segmentedControl.setImage(Tab.messages.image, forSegmentAt: Tab.messages.rawValue)
            }
        }))
    }
    
    override func loadView() {
        self.view = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    }
    
    var contentView: UIView {
        let view = self.view as! UIVisualEffectView
        return view.contentView
    }
    
    override func viewDidLoad() {
        self.contentView.addSubview(self.leadingSeparatorView)
        self.contentView.addSubview(self.topSeparatorView)
        self.contentView.addSubview(self.segmentedControl)
        
        self.clueListViewController.willMove(toParent: self)
        self.addChild(self.clueListViewController)
        self.contentView.addSubview(self.clueListViewController.view)
        self.clueListViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.clueListViewController.viewRespectsSystemMinimumLayoutMargins = false
        self.clueListViewController.view.layoutMargins = Self.subviewLayoutMargins
        self.clueListViewController.didMove(toParent: self)
        
        self.contentView.addSubview(self.messagesViewController.view)
        self.messagesViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.messagesViewController.viewRespectsSystemMinimumLayoutMargins = false
        self.messagesViewController.view.layoutMargins = Self.subviewLayoutMargins
        self.messagesViewController.view.layer.opacity = 0
        self.messagesViewController.view.isHidden = true
        
        self.playersViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.playersViewController.view)
        self.playersViewController.viewRespectsSystemMinimumLayoutMargins = false
        self.playersViewController.view.layoutMargins = Self.subviewLayoutMargins
        self.playersViewController.view.layer.opacity = 0
        self.playersViewController.view.isHidden = true
        
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControl.addTarget(self, action: #selector(selectedSegmentDidChange(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            self.leadingSeparatorView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.leadingSeparatorView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.leadingSeparatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.topSeparatorView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.topSeparatorView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.topSeparatorView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
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
        self.updateVisibleTab(animated: true)
    }

    func setCurrentTab(_ tab: Tab, animated: Bool) {
        let work = {
            self.segmentedControl.selectedSegmentIndex = tab.rawValue
            self.updateVisibleTab(animated: animated)
        }

        if animated {
            work()
        } else {
            UIView.performWithoutAnimation {
                work()
                self.segmentedControl.layoutIfNeeded()
            }
        }
    }

    func updateVisibleTab(animated: Bool) {
        switch self.currentTab {
            case .clues:
                self.show(viewController: self.clueListViewController, animated: animated)
                self.hide(viewController: self.messagesViewController, animated: animated)
                self.hide(viewController: self.playersViewController, animated: animated)
                self.delegate?.sideBarViewController(self, didSwitchToTab: .clues)
            case .messages:
                self.show(viewController: self.messagesViewController, animated: animated)
                self.hide(viewController: self.clueListViewController, animated: animated)
                self.hide(viewController: self.playersViewController, animated: animated)
                self.delegate?.sideBarViewController(self, didSwitchToTab: .messages)
            case .players:
                self.hide(viewController: self.clueListViewController, animated: animated)
                self.hide(viewController: self.messagesViewController, animated: animated)
                self.show(viewController: self.playersViewController, animated: animated)
                self.delegate?.sideBarViewController(self, didSwitchToTab: .players)
        }
    }

    func show(viewController: UIViewController, animated: Bool) {
        if !viewController.view.isHidden {
            return
        }

        viewController.beginAppearanceTransition(true, animated: true)
        viewController.willMove(toParent: self)
        self.addChild(viewController)
        viewController.didMove(toParent: self)

        if animated {
            ShowHideAnimationHelpers.show(view: viewController.view) {
                viewController.endAppearanceTransition()
            }
        } else {
            viewController.view.isHidden = false
            viewController.view.alpha = 1
            viewController.endAppearanceTransition()
        }
    }

    func hide(viewController: UIViewController, animated: Bool) {
        if viewController.view.isHidden {
            return
        }

        viewController.beginAppearanceTransition(false, animated: true)
        viewController.willMove(toParent: nil)
        viewController.removeFromParent()
        viewController.didMove(toParent: nil)

        if animated {
            ShowHideAnimationHelpers.hide(view: viewController.view) {
                viewController.endAppearanceTransition()
            }
        } else {
            viewController.view.isHidden = true
            viewController.endAppearanceTransition()
        }
    }

}
