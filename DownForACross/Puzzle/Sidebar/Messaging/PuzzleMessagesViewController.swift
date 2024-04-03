//
//  PuzzleMessagesViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 1/31/24.
//

import UIKit
import Combine

class PuzzleMessagesViewController: UIViewController {
    
    let messageCellReuseIdentifier: String = "messageCellReuseIdentifier"
    lazy var dataSource = UITableViewDiffableDataSource<Int, MessageAndPlayer>(
        tableView: self.tableView,
        cellProvider: { [weak self] tableView, indexPath, item in
            guard let self else { return nil }
            return self.createCell(tableView: tableView, indexPath: indexPath, messageAndPlayer: item)
        })

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    var selfUserId: String = ""

    @Published
    var hasUnreadMessages = false

    lazy var goToBottomButton: UIView = {
        let button = UIButton(configuration: .plain())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration?.image = UIImage(systemName: "chevron.down")
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        button.addTarget(self, action: #selector(goToBottomButtonTapped), for: .primaryActionTriggered)
        button.layer.cornerRadius = 19
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.ChatMessage.borderOther.cgColor
        button.layer.borderWidth = 1
        button.backgroundColor = UIColor.ChatMessage.backgroundOther
        button.isHidden = true

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 38),
            button.heightAnchor.constraint(equalToConstant: 38)
        ])
        return button
    }()

    var tableViewBottomContentOffset: CGFloat {
        return self.tableView.contentSize.height - self.tableView.frame.size.height + self.tableView.contentInset.bottom
    }

    private let settingsStorage: SettingsStorage
    private var needsContentOffsetAdjustment = true
    private var isFollowingBottom = true
    private var isVisible: Bool = false
    private var messagesNeedingAnimation: [MessageAndPlayer] = []
    private var messageIds: Set<String> = Set()
    private var playersSubscription: AnyCancellable?
    private var players: [String: Player] = [:] {
        didSet {
            self.tableView.reloadData()
        }
    }

    private var messages: [MessageAndPlayer] = [] {
        didSet {
            self.startTheConversationLabel.isHidden = messages.count > 0
            var snapshot = NSDiffableDataSourceSnapshot<Int, MessageAndPlayer>()
            snapshot.appendSections([0])
            snapshot.appendItems(messages, toSection: 0)
            self.dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
    
    lazy var startTheConversationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Start the conversation!"
        label.textColor = .placeholderText
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.numberOfLines = 0
        
        return label
    }()

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(gameClient: GameClient, settingsStorage: SettingsStorage) {
        self.settingsStorage = settingsStorage
        super.init(nibName: nil, bundle: nil)
        self.playersSubscription = gameClient.$players.sink(receiveValue: { [weak self] newValue in
            self?.players = newValue
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.tableView.backgroundColor = .clear
        self.tableView.separatorStyle = .none
        self.tableView.register(PuzzleMessageCell.self, forCellReuseIdentifier: self.messageCellReuseIdentifier)
        self.tableView.dataSource = self.dataSource
        self.tableView.delegate = self

        self.view.addSubview(self.tableView)
        self.view.addSubview(self.startTheConversationLabel)
        self.view.addSubview(self.goToBottomButton)

        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            self.startTheConversationLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.startTheConversationLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.startTheConversationLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),

            self.goToBottomButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8),
            self.goToBottomButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        if self.needsContentOffsetAdjustment {
            self.view.setNeedsLayout()
        }
        
        super.viewWillAppear(animated)
        self.hasUnreadMessages = false
        self.isVisible = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.isVisible = false
        self.needsContentOffsetAdjustment = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.isVisible {
            if self.needsContentOffsetAdjustment && self.isFollowingBottom {
                self.tableView.contentOffset.y = self.tableViewBottomContentOffset
            }
            self.needsContentOffsetAdjustment = false
        }

        self.goToBottomButton.layer.borderColor = UIColor.ChatMessage.borderOther.cgColor
    }

    func createCell(tableView: UITableView, indexPath: IndexPath, messageAndPlayer: MessageAndPlayer) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.messageCellReuseIdentifier, for: indexPath) as! PuzzleMessageCell
        cell.mode = (messageAndPlayer.message.senderId == self.selfUserId) ? .sentBySelf : .sentByOther
        cell.messageLabel.text = messageAndPlayer.message.message
        
        if let player = self.players[messageAndPlayer.playerId] {
            cell.senderLabel.text = player.displayName
            cell.senderLabel.textColor = player.color
        } else {
            cell.senderLabel.text = "Unknown player"
            cell.senderLabel.textColor = UIColor.lightGray
        }

        if self.messagesNeedingAnimation.contains(messageAndPlayer) {
            cell.bubbleView.isHidden = true
            cell.bubbleView.layer.opacity = 0
        }
        
        return cell
    }
    
    func addMessage(_ message: MessageAndPlayer) {
        guard !self.messageIds.contains(message.id) else { return }

        if !(self.isVisible && self.isFollowingBottom) && self.settingsStorage.showUnreadMessageBadges {
            self.hasUnreadMessages = true
        }

        self.messagesNeedingAnimation.append(message)
        self.messages.append(message)
        self.messageIds.insert(message.id)
        
        // start following the bottom again if the user is the sender
        self.isFollowingBottom = self.isFollowingBottom || message.playerId == self.selfUserId

        if self.isFollowingBottom, let insertedIndexPath = self.dataSource.indexPath(for: message) {
            self.tableView.scrollToRow(at: insertedIndexPath, at: .bottom, animated: true)
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let willEndAtBottom = (abs(targetContentOffset.pointee.y - self.tableViewBottomContentOffset) < 1)

        // this is a reasonable proxy since the go to bottom button is only visible when the last cell is visible
        let lastCellVisible = self.goToBottomButton.isHidden

        self.isFollowingBottom = (willEndAtBottom || lastCellVisible)
    }

    @objc func goToBottomButtonTapped() {
        guard let lastIndexPath = self.dataSource.lastIndexPath(in: self.tableView) else { return }
        self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        self.isFollowingBottom = false
    }

    func isLastIndexPath(_ indexPath: IndexPath) -> Bool {
        guard let lastIndexPath = self.dataSource.lastIndexPath(in: self.tableView) else { return false }
        return indexPath == lastIndexPath
    }

}

extension PuzzleMessagesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PuzzleMessageCell {
            if let message = self.dataSource.itemIdentifier(for: indexPath),
               let animationIndex = self.messagesNeedingAnimation.firstIndex(of: message) {
                ShowHideAnimationHelpers.show(view: cell.bubbleView, duration: 0.3)
                self.messagesNeedingAnimation.remove(at: animationIndex)
            } else {
                cell.bubbleView.isHidden = false
                cell.bubbleView.layer.opacity = 1
            }
        }

        if self.isLastIndexPath(indexPath) {
            ShowHideAnimationHelpers.hide(view: self.goToBottomButton)

            if self.isVisible {
                self.hasUnreadMessages = false
            }
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.isLastIndexPath(indexPath) {
            ShowHideAnimationHelpers.show(view: self.goToBottomButton)
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}
