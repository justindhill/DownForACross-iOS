//
//  SettingsViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 2/9/24.
//

import UIKit

class SettingsViewController: UIViewController {
    
    let stackView: UIStackView
    let scrollView: UIScrollView
    let settingsStorage: SettingsStorage
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(settingsStorage: SettingsStorage) {
        self.settingsStorage = settingsStorage
        self.stackView = UIStackView()
        self.stackView.axis = .vertical
        self.stackView.isLayoutMarginsRelativeArrangement = true
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.preservesSuperviewLayoutMargins = true
        self.scrollView = UIScrollView()
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.preservesSuperviewLayoutMargins = true
        self.scrollView.contentInsetAdjustmentBehavior = .never
        super.init(nibName: nil, bundle: nil)
        
        self.navigationItem.title = "Settings"
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = .systemBackground
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.stackView)
        
        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.leadingAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.layoutMarginsGuide.trailingAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor),
            self.stackView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor),
            self.scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor)
        ])
        
        self.updateContent()
    }
    
    func updateContent() {
        self.addSettingHeader(title: "Display name",
                              description: "How you will appear to other players in chat messages and the player list",
                              to: self.stackView)
        
        self.addSettingHeader(title: "Cursor color", description: "The cursor color that will represent you to other players", to: self.stackView)
    }
    
    func addSettingHeader(title: String, description: String, to: UIStackView) {
        if to.arrangedSubviews.count > 0, let last = to.arrangedSubviews.last {
            let separator = UIView()
            NSLayoutConstraint.activate([separator.heightAnchor.constraint(equalToConstant: 1)])
            separator.backgroundColor = .separator
            to.addArrangedSubview(separator)
            to.setCustomSpacing(8, after: last)
            to.setCustomSpacing(8, after: separator)
        }
        
        let titleSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: titleSize, weight: .semibold)
        titleLabel.text = title
        titleLabel.textColor = UIColor.label
        titleLabel.numberOfLines = 0
        to.addArrangedSubview(titleLabel)
        
        to.setCustomSpacing(4, after: titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        descriptionLabel.text = description
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        to.addArrangedSubview(descriptionLabel)
    }
    
}
