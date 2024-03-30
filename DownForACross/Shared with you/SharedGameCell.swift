//
//  SharedGameCell.swift
//  DownForACross
//
//  Created by Justin Hill on 3/28/24.
//

import UIKit
import SharedWithYou

class SharedGameCell: UITableViewCell {

    private let attributionView: SWAttributionView = SWAttributionView()

    var sharingHighlight: SWHighlight? {
        didSet {
            if let sharingHighlight {
                self.attributionView.highlight = sharingHighlight
                self.attributionView.isHidden = false
            } else {
                self.attributionView.highlight = sharingHighlight
                self.attributionView.isHidden = true
            }
        }
    }

    var sharedGame: ResolvedSharedGame?

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .label

        return label
    }()

    let authorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel

        return label
    }()

    var obscuresLabels: Bool = false {
        didSet {
            if obscuresLabels {
                self.obscure(label: self.titleLabel)
                self.obscure(label: self.authorLabel)
            } else {
                self.unobscure(label: self.titleLabel, textColor: .label)
                self.unobscure(label: self.authorLabel, textColor: .secondaryLabel)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.attributionView.translatesAutoresizingMaskIntoConstraints = false
        self.attributionView.horizontalAlignment = .leading

        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.authorLabel)

        NSLayoutConstraint.activate([
            self.titleLabel.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            self.authorLabel.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            self.authorLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            self.authorLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 4),
            self.contentView.layoutMarginsGuide.bottomAnchor.constraint(greaterThanOrEqualTo: self.authorLabel.bottomAnchor)
        ])
    }

    private func obscure(label: UILabel) {
        label.textColor = .clear
        label.backgroundColor = .separator
        label.layer.cornerRadius = 2
        label.layer.masksToBounds = true
    }

    private func unobscure(label: UILabel, textColor: UIColor) {
        label.textColor = textColor
        label.backgroundColor = .clear
        label.layer.masksToBounds = false
    }

    override func layoutSubviews() {
        if self.attributionView.superview == nil {
            self.contentView.addSubview(self.attributionView)

            NSLayoutConstraint.activate([
                self.attributionView.topAnchor.constraint(equalTo: self.authorLabel.bottomAnchor, constant: 8),
                self.attributionView.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
                self.attributionView.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
                self.contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: self.attributionView.bottomAnchor)
            ])

            self.invalidateIntrinsicContentSize()
        }

        super.layoutSubviews()
    }

}
