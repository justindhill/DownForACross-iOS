//
//  PuzzleMessageCell.swift
//  DownForACross
//
//  Created by Justin Hill on 2/26/24.
//

import UIKit

class PuzzleMessageCell: UITableViewCell {
    
    enum Mode {
        case sentBySelf
        case sentByOther
    }
    
    var mode: Mode = .sentByOther {
        didSet {
            if oldValue != mode {
                self.modeDidChange()
            }
        }
    }
    
    let bubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        
        return view
    }()
    
    let senderLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    var sentBySelfConstraints: [NSLayoutConstraint]!
    var sentByOtherConstraints: [NSLayoutConstraint]!
    var bubbleLeadingConstraint: NSLayoutConstraint!
    var bubbleTrailingConstraint: NSLayoutConstraint!
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        self.bubbleView.addSubview(self.senderLabel)
        self.bubbleView.addSubview(self.messageLabel)
        self.contentView.addSubview(self.bubbleView)
        self.backgroundColor = .clear
        self.bubbleView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        self.sentBySelfConstraints = [
            self.messageLabel.topAnchor.constraint(equalTo: self.bubbleView.layoutMarginsGuide.topAnchor),
            self.bubbleView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        ]
        
        self.sentByOtherConstraints = [
            self.messageLabel.topAnchor.constraint(equalTo: self.senderLabel.bottomAnchor),
            self.bubbleView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8),
            self.senderLabel.trailingAnchor.constraint(equalTo: self.bubbleView.layoutMarginsGuide.trailingAnchor)
        ]
        
        self.registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(appearanceDidChange))
        
        var initialConstraints = self.sentByOtherConstraints!
        initialConstraints.append(contentsOf: [
            self.bubbleView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            self.bubbleView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8),
            self.senderLabel.topAnchor.constraint(equalTo: self.bubbleView.layoutMarginsGuide.topAnchor),
            self.senderLabel.leadingAnchor.constraint(equalTo: self.bubbleView.layoutMarginsGuide.leadingAnchor),
            self.messageLabel.leadingAnchor.constraint(equalTo: self.bubbleView.layoutMarginsGuide.leadingAnchor),
            self.messageLabel.trailingAnchor.constraint(equalTo: self.bubbleView.layoutMarginsGuide.trailingAnchor),
            self.messageLabel.bottomAnchor.constraint(equalTo: self.bubbleView.layoutMarginsGuide.bottomAnchor),
            self.bubbleView.widthAnchor.constraint(lessThanOrEqualTo: self.contentView.widthAnchor, multiplier: 0.75)
        ])
        
        self.modeDidChange()
        self.appearanceDidChange()
        
        NSLayoutConstraint.activate(initialConstraints)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.bubbleView.layer.cornerRadius = (self.messageLabel.font.lineHeight / 2) + self.bubbleView.layoutMargins.top
    }
    
    func modeDidChange() {
        switch self.mode {
            case .sentBySelf:
                NSLayoutConstraint.deactivate(self.sentByOtherConstraints)
                NSLayoutConstraint.activate(self.sentBySelfConstraints)
                self.senderLabel.isHidden = true
                self.bubbleView.backgroundColor = UIColor.ChatMessage.backgroundSelf
                self.messageLabel.textColor = UIColor.ChatMessage.textSelf
                self.bubbleView.layer.borderWidth = 0
            case .sentByOther:
                NSLayoutConstraint.deactivate(self.sentBySelfConstraints)
                NSLayoutConstraint.activate(self.sentByOtherConstraints)
                self.senderLabel.isHidden = false
                self.bubbleView.layer.borderWidth = 1
                self.bubbleView.layer.masksToBounds = true
                self.bubbleView.backgroundColor = UIColor.ChatMessage.backgroundOther
                self.messageLabel.textColor = UIColor.ChatMessage.textOther
        }
    }
    
    @objc func appearanceDidChange() {
        self.bubbleView.layer.borderColor = UIColor.ChatMessage.borderOther.cgColor
    }
    
}
