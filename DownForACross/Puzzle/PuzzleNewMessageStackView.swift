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
    
    func addChatMessage(_ chatEvent: ChatEvent, from: Player) {
        if self.seenMessages.contains(chatEvent.messageId) {
            return
        }
        
        if self.stackView.arrangedSubviews.filter({ $0.tag != Self.removedViewTag }).count == self.concurrentViewCap,
            let firstView = self.stackView.arrangedSubviews.first(where: { $0.tag != Self.removedViewTag }) {
            
            self.remove(view: firstView, animated: true)
        }
        
        self.seenMessages.insert(chatEvent.messageId)
        
        let bubbleView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 12
        bubbleView.layer.cornerCurve = .continuous
        bubbleView.layer.masksToBounds = true
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(from.displayName): \(chatEvent.message)"
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false

        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bubbleTapped)))

        bubbleView.contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: bubbleView.contentView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: bubbleView.contentView.layoutMarginsGuide.trailingAnchor),
            label.topAnchor.constraint(equalTo: bubbleView.contentView.layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: bubbleView.contentView.layoutMarginsGuide.bottomAnchor)
        ])
        
        self.stackView.addArrangedSubview(bubbleView)
        self.layoutIfNeeded()
        self.heightConstraint.constant = self.stackView.frame.size.height

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.superview?.layoutIfNeeded()
        }

        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            if bubbleView.superview != nil {
                self.remove(view: bubbleView, animated: true)
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

    @objc func bubbleTapped() {
        self.stackView.arrangedSubviews.forEach { view in
            self.remove(view: view, animated: true)
        }

        self.delegate?.messageStackViewDidSelectMessage(self)
    }
}
