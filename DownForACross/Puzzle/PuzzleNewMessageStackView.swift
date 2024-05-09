//
//  PuzzleNewMessageStackView.swift
//  DownForACross
//
//  Created by Justin Hill on 2/1/24.
//

import Foundation
import UIKit

protocol PuzzleNewMessageStackViewDelegate: AnyObject {
    func messageStackViewDidSelectMessage(_ view: PuzzleNewMessageStackView)
}

class PuzzleNewMessageStackView: UIView {
    
    static let removedViewTag: Int = 999
    let concurrentViewCap: Int = 3
    
    var seenMessages: Set<String> = Set()
    weak var delegate: PuzzleNewMessageStackViewDelegate?

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .trailing
        return stackView
    }()
    
    var heightConstraint: NSLayoutConstraint!
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(frame: .zero)
        
        self.clipsToBounds = true
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.heightConstraint = self.heightAnchor.constraint(equalToConstant: 0)
        
        self.addSubview(self.stackView)
        NSLayoutConstraint.activate([
            self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.topAnchor),
            self.heightConstraint
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.stackView.arrangedSubviews.forEach { view in
            view.layer.borderColor = UIColor.ChatMessage.previewBorder.cgColor
        }
    }

    func addChatMessage(_ chatEvent: ChatEvent, from: Player) {
        if self.seenMessages.contains(chatEvent.messageId) {
            return
        }
        
        if self.stackView.arrangedSubviews.filter({ $0.tag != Self.removedViewTag }).count == self.concurrentViewCap,
            let firstView = self.stackView.arrangedSubviews.first(where: { $0.tag != Self.removedViewTag }) {
            
            self.remove(view: firstView, animated: true)
        }
        
        self.seenMessages.insert(chatEvent.messageId)
        
        let messageView = self.createMessageView(player: from, message: chatEvent.message)
        self.stackView.addArrangedSubview(messageView)
        self.layoutIfNeeded()
        self.heightConstraint.constant = self.stackView.frame.size.height

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.superview?.layoutIfNeeded()
        }

        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            if messageView.superview != nil {
                self.remove(view: messageView, animated: true)
            }
        }
    }
    
    func addSystemMessage(_ message: String) {
        let event = ChatEvent(gameId: "", senderId: "", senderName: "", message: message)
        event.messageId = UUID().uuidString

        self.addChatMessage(event,
                            from: Player(userId: "SYSTEM", displayName: "Pro tip!", color: UIColor.systemBlue))
    }
    
    func remove(view: UIView, animated: Bool) {
        guard view.tag != Self.removedViewTag else { return }
        view.tag = Self.removedViewTag
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                view.alpha = 0
            } completion: { _ in
                self.stackView.removeArrangedSubview(view)
                self.layoutIfNeeded()
                self.heightConstraint.constant = self.stackView.frame.size.height
            }
        } else {
            self.stackView.removeArrangedSubview(view)
            self.layoutIfNeeded()
            self.heightConstraint.constant = self.stackView.frame.size.height
        }
    }

    func createMessageView(player: Player, message: String) -> UIView {
        var icon: UIImage!
        if player.userId == "SYSTEM" {
            icon = UIImage(systemName: "lightbulb.circle")?.withRenderingMode(.alwaysTemplate)
        } else {
            icon = UIImage(systemName: "message.circle")?.withRenderingMode(.alwaysTemplate)
        }

        let bubbleView = UIView()
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 12
        bubbleView.layer.cornerCurve = .continuous
        bubbleView.layer.masksToBounds = true
        bubbleView.backgroundColor = UIColor.ChatMessage.previewBackground
        bubbleView.layer.borderColor = UIColor.ChatMessage.previewBorder.cgColor
        bubbleView.layer.borderWidth = 1

        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        messageLabel.numberOfLines = 2
        messageLabel.isUserInteractionEnabled = false
        messageLabel.text = message

        let playerLabel = UILabel()
        playerLabel.translatesAutoresizingMaskIntoConstraints = false
        playerLabel.attributedText = self.titleString(icon: icon, color: player.color, text: player.displayName)
        playerLabel.numberOfLines = 1
        playerLabel.font = UIFont.boldSystemFont(ofSize: messageLabel.font.pointSize)
        playerLabel.isUserInteractionEnabled = false

        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bubbleTapped)))

        bubbleView.addSubview(playerLabel)
        bubbleView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            playerLabel.leadingAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.leadingAnchor),
            playerLabel.trailingAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.trailingAnchor),
            playerLabel.topAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.topAnchor),
            messageLabel.topAnchor.constraint(equalTo: playerLabel.bottomAnchor, constant: 2),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.bottomAnchor)
        ])

        return bubbleView
    }

    func titleString(icon: UIImage, color: UIColor, text: String) -> NSAttributedString {
        let textAttachment = NSTextAttachment(image: icon)
        var attributedString = NSMutableAttributedString(string: "\(UnicodeScalar(NSTextAttachment.character)!)", attributes: [
            .attachment: textAttachment
        ])
        attributedString.append(NSAttributedString(string: " " + text))
        attributedString.addAttributes([
            .foregroundColor: color
        ], range: NSRange(location: 0, length: attributedString.length))

        return attributedString
    }

    @objc func bubbleTapped() {
        self.stackView.arrangedSubviews.forEach { view in
            self.remove(view: view, animated: true)
        }

        self.delegate?.messageStackViewDidSelectMessage(self)
    }
}
