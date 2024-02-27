//
//  PuzzleMessagesViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 1/31/24.
//

import UIKit

class PuzzleMessagesViewController: UIViewController {
    
    let messageCellReuseIdentifier: String = "messageCellReuseIdentifier"
    lazy var dataSource = UITableViewDiffableDataSource<Int, MessageAndPlayer>(
        tableView: self.tableView,
        cellProvider: self.createCell)
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    var selfUserId: String = ""
    
    private var messagesNeedingAnimation: [MessageAndPlayer] = []
    private var messageIds: Set<String> = Set()
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
        
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            self.startTheConversationLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.startTheConversationLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8),
            self.startTheConversationLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8)
        ])
    }
    
    func createCell(tableView: UITableView, indexPath: IndexPath, messageAndPlayer: MessageAndPlayer) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.messageCellReuseIdentifier, for: indexPath) as! PuzzleMessageCell
        cell.mode = (messageAndPlayer.message.senderId == self.selfUserId) ? .sentBySelf : .sentByOther
        cell.messageLabel.text = messageAndPlayer.message.message
        cell.senderLabel.text = messageAndPlayer.player.displayName
        cell.senderLabel.textColor = messageAndPlayer.player.color
        if self.messagesNeedingAnimation.contains(messageAndPlayer) {
            cell.bubbleView.layer.opacity = 0
        }
        
        return cell
    }
    
    func addMessage(_ message: MessageAndPlayer) {
        guard !self.messageIds.contains(message.id) else { return }
        
        let isAtBottom = (self.tableView.contentSize.height - self.tableView.frame.size.height - self.tableView.contentOffset.y) < 20
        self.messagesNeedingAnimation.append(message)
        self.messages.append(message)
        self.messageIds.insert(message.id)
        
        if isAtBottom, let insertedIndexPath = self.dataSource.indexPath(for: message) {
            self.tableView.scrollToRow(at: insertedIndexPath, at: .bottom, animated: true)
        }
    }
    
}

extension PuzzleMessagesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let message = self.dataSource.itemIdentifier(for: indexPath),
           let animationIndex = self.messagesNeedingAnimation.firstIndex(of: message),
           let cell = cell as? PuzzleMessageCell {
            ShowHideAnimationHelpers.show(view: cell.bubbleView, duration: 0.3)
            self.messagesNeedingAnimation.remove(at: animationIndex)
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}
