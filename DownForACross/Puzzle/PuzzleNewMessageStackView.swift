//
//  PuzzleNewMessageStackView.swift
//  DownForACross
//
//  Created by Justin Hill on 2/1/24.
//

import Foundation
import UIKit

class PuzzleNewMessageStackView: UIView {
    
    var seenMessages: Set<String> = Set()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .trailing
        return stackView
    }()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(frame: .zero)
        
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.stackView)
        NSLayoutConstraint.activate([
            self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.topAnchor),
            self.stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    func addChatMessage(_ chatEvent: ChatEvent, from: Player) {
        if self.seenMessages.contains(chatEvent.messageId) {
            return
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
        
        bubbleView.contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: bubbleView.contentView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: bubbleView.contentView.layoutMarginsGuide.trailingAnchor),
            label.topAnchor.constraint(equalTo: bubbleView.contentView.layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: bubbleView.contentView.layoutMarginsGuide.bottomAnchor)
        ])
        
        self.stackView.addArrangedSubview(bubbleView)
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            if bubbleView.superview != nil {
                self.remove(view: bubbleView, animated: true)
            }
        }
    }
    
    func addSystemMessage(_ message: String) {
        
    }
    
    func remove(view: UIView, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                view.alpha = 0
            } completion: { _ in
                self.stackView.removeArrangedSubview(view)
            }
        } else {
            self.stackView.removeArrangedSubview(view)
        }
    }
}
