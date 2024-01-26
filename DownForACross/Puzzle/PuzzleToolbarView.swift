//
//  PuzzleToolbarView.swift
//  DownForACross
//
//  Created by Justin Hill on 1/24/24.
//

import UIKit

class PuzzleToolbarView: UIVisualEffectView {
    
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
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(effect: UIBlurEffect(style: .systemThickMaterial))
        self.contentView.addSubview(self.leftButton)
        self.contentView.addSubview(self.rightButton)
        self.contentView.addSubview(self.clueLabel)
        self.contentView.preservesSuperviewLayoutMargins = false
        self.contentView.layoutMargins = .zero
        
        NSLayoutConstraint.activate([
            self.leftButton.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.leftButton.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.leftButton.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor),
            self.clueLabel.leadingAnchor.constraint(equalTo: self.leftButton.trailingAnchor),
            self.clueLabel.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor, constant: 8),
            self.clueLabel.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor, constant: -8),
            self.rightButton.leadingAnchor.constraint(equalTo: self.clueLabel.trailingAnchor),
            self.rightButton.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.rightButton.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.rightButton.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor)
        ])
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
    
}
