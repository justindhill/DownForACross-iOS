//
//  BaseSettingView.swift
//  DownForACross
//
//  Created by Justin Hill on 3/19/24.
//

import UIKit

class BaseSettingView: UIView {

    static let layoutMargins: UIEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    let title: String
    let details: String?
    let labelSpacing: CGFloat = 8.0

    private let accessoryView: UIView?
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()

    private lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(title: String, details: String?, accessoryView: UIView?) {
        self.title = title
        self.details = details
        self.accessoryView = accessoryView
        accessoryView?.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: .zero)

        self.layoutMargins = Self.layoutMargins

        self.titleLabel.text = title
        if let details {
            self.detailsLabel.text = details
        }

        self.addSubview(self.titleLabel)

        var constraints: [NSLayoutConstraint] = [
            self.titleLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.layoutMarginsGuide.trailingAnchor),
            self.titleLabel.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            self.titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: self.layoutMarginsGuide.bottomAnchor)
        ]

        if let accessoryView {
            self.addSubview(accessoryView)
            constraints.append(contentsOf: [
                accessoryView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
                self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: accessoryView.leadingAnchor)
            ])

            if accessoryView is UILabel || accessoryView is UIButton {
                constraints.append(accessoryView.lastBaselineAnchor.constraint(equalTo: self.titleLabel.lastBaselineAnchor))
            } else {
                constraints.append(accessoryView.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor))
            }
        }

        if details != nil {
            self.addSubview(self.detailsLabel)
            constraints.append(contentsOf: [
                self.detailsLabel.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
                self.detailsLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.layoutMarginsGuide.trailingAnchor),
                self.detailsLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: self.labelSpacing),
                self.detailsLabel.bottomAnchor.constraint(lessThanOrEqualTo: self.layoutMarginsGuide.bottomAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }

    func cancel() {
        // override point
    }

}
