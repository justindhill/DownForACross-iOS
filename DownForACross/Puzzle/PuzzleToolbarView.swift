//
//  PuzzleToolbarView.swift
//  DownForACross
//
//  Created by Justin Hill on 1/24/24.
//

import UIKit

class PuzzleToolbarView: UIVisualEffectView {
    
    enum Mode {
        case clues
        case messages
    }
    
    var mode: Mode = .clues {
        didSet { self.updateVisibleViews() }
    }
    
    let clueModeContainer: UIView = UIView()
    lazy var leftButton: UIButton = self.createDirectionButton(isLeft: true)
    lazy var rightButton: UIButton = self.createDirectionButton(isLeft: false)
    lazy var clueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = "This is a clue for one of the words in the puzzle."
        return label
    }()
    
    let messageModeContainer: UIView = UIView()
    let messagePlaceholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .placeholderText
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "Message"
        label.isUserInteractionEnabled = false
        
        return label
    }()
    
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.textContainerInset = UIEdgeInsets(top: 7, left: 8, bottom: 4, right: 8)
        textView.backgroundColor = UIColor.systemGray2
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.cornerRadius = 17
        textView.layer.cornerCurve = .continuous
        textView.layer.masksToBounds = true
        textView.isScrollEnabled = false
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        return textView
    }()
    let sendButton: UIButton = {
        let button = UIButton(configuration: .plain())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration?.image = UIImage(systemName: "arrow.up.circle.fill",
                                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 22))
        button.isEnabled = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 50)
        ])
        return button
    }()
    
    var clueModeConstraints: [NSLayoutConstraint]!
    var messageModeConstraints: [NSLayoutConstraint]!
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(effect: UIBlurEffect(style: .systemThickMaterial))
        self.clueModeContainer.translatesAutoresizingMaskIntoConstraints = false
        self.messageModeContainer.translatesAutoresizingMaskIntoConstraints = false
        self.messageTextView.translatesAutoresizingMaskIntoConstraints = false
        self.messageModeContainer.isHidden = true
        
        self.registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { (self: Self, previousTraitCollection: UITraitCollection) in
            self.updateTextViewAppearance()
        })
        self.clueModeContainer.addSubview(self.leftButton)
        self.clueModeContainer.addSubview(self.rightButton)
        self.clueModeContainer.addSubview(self.clueLabel)
        
        self.messageModeContainer.addSubview(self.messageTextView)
        self.messageModeContainer.addSubview(self.sendButton)
        self.messageModeContainer.addSubview(self.messagePlaceholderLabel)
        self.updateTextViewAppearance()
        
        self.contentView.addSubview(self.clueModeContainer)
        self.contentView.addSubview(self.messageModeContainer)
        self.contentView.preservesSuperviewLayoutMargins = false
        self.contentView.layoutMargins = .zero
        
        self.clueModeConstraints = [
            self.clueModeContainer.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor)
        ]
        
        self.messageModeConstraints = [
            self.messageModeContainer.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate([
            self.leftButton.leadingAnchor.constraint(equalTo: self.clueModeContainer.leadingAnchor),
            self.leftButton.topAnchor.constraint(equalTo: self.clueModeContainer.topAnchor),
            self.leftButton.bottomAnchor.constraint(equalTo: self.clueModeContainer.bottomAnchor),
            self.clueLabel.leadingAnchor.constraint(equalTo: self.leftButton.trailingAnchor),
            self.clueLabel.topAnchor.constraint(equalTo: self.clueModeContainer.topAnchor, constant: 8),
            self.clueLabel.bottomAnchor.constraint(equalTo: self.clueModeContainer.bottomAnchor, constant: -8),
            self.rightButton.leadingAnchor.constraint(equalTo: self.clueLabel.trailingAnchor),
            self.rightButton.trailingAnchor.constraint(equalTo: self.clueModeContainer.trailingAnchor),
            self.rightButton.topAnchor.constraint(equalTo: self.clueModeContainer.topAnchor),
            self.rightButton.bottomAnchor.constraint(equalTo: self.clueModeContainer.bottomAnchor),
            
            self.messageTextView.leadingAnchor.constraint(equalTo: self.messageModeContainer.leadingAnchor, constant: 12),
            self.messageTextView.topAnchor.constraint(equalTo: self.messageModeContainer.topAnchor, constant: 8),
            self.messageTextView.bottomAnchor.constraint(equalTo: self.messageModeContainer.bottomAnchor, constant: -8),
            self.messageTextView.trailingAnchor.constraint(equalTo: self.sendButton.leadingAnchor),
            self.messageTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 34),
            self.messagePlaceholderLabel.leadingAnchor.constraint(equalTo: self.messageTextView.leadingAnchor, constant: 12),
            self.messagePlaceholderLabel.centerYAnchor.constraint(equalTo: self.messageTextView.centerYAnchor),
            
            self.sendButton.bottomAnchor.constraint(equalTo: self.messageModeContainer.bottomAnchor),
            self.sendButton.trailingAnchor.constraint(equalTo: self.messageModeContainer.trailingAnchor),
            
            self.messageModeContainer.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.messageModeContainer.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.messageModeContainer.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.clueModeContainer.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.clueModeContainer.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.clueModeContainer.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor)
        ])
        
        self.messageTextView.delegate = self
        
        NSLayoutConstraint.activate(self.clueModeConstraints)
    }
    
    func updateVisibleViews() {
        guard (self.mode == .clues && self.clueModeContainer.isHidden) ||
              (self.mode == .messages && self.messageModeContainer.isHidden) else {
            return
        }
        
        CATransaction.begin()
        let transition = CATransition()
        transition.duration = 0.1
        transition.type = CATransitionType.fade
        transition.fillMode = .forwards
        
        self.clueModeContainer.isHidden = self.mode != .clues
        self.messageModeContainer.isHidden = self.mode != .messages
        
        self.contentView.layer.add(transition, forKey: nil)
        
        CATransaction.commit()
        
        if self.mode == .messages {
            NSLayoutConstraint.deactivate(self.clueModeConstraints)
            NSLayoutConstraint.activate(self.messageModeConstraints)
            self.messageTextView.becomeFirstResponder()
        } else {
            NSLayoutConstraint.activate(self.clueModeConstraints)
            NSLayoutConstraint.deactivate(self.messageModeConstraints)
        }
    }
    
    func createDirectionButton(isLeft: Bool) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.\(isLeft ? "left" : "right").circle.fill")
        let button = UIButton(configuration: config)
        button.contentVerticalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        return button
    }
    
    func updateTextViewAppearance() {
        self.messageTextView.layer.borderColor = self.traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray3.cgColor : UIColor.systemGray5.cgColor
        self.messageTextView.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .systemGray4 : .white
    }
    
}

extension PuzzleToolbarView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let isSendable = textView.text.count > 0
        self.messagePlaceholderLabel.isHidden = isSendable
        self.sendButton.isEnabled = isSendable
    }
    
}
