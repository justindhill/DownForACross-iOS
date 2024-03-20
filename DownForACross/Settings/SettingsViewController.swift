//
//  SettingsViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 2/9/24.
//

import UIKit

protocol SettingsDisplayable: CaseIterable {
    var displayString: String { get }
}

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

        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedInView))
        self.view.addGestureRecognizer(tap)

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
        self.stackView.addArrangedSubview(EditableTextSettingView(
            title: "Display name",
            details: "How you will appear to other players in chat messages and the player list",
            settingsStorage: self.settingsStorage,
            keyPath: \.userDisplayName))

        self.stackView.addArrangedSubview(SingleSelectSettingView(
            title: "Appearance",
            settingsStorage: self.settingsStorage,
            keyPath: \.appearanceStyle, 
            updateHandler: { newValue in
                self.view.window?.rootViewController?.view.overrideUserInterfaceStyle = newValue.userInterfaceStyle
            }))
//
//        self.addSettingHeader(title: "Default input mode", description: "The input mode that will be initiallly selected when you start a game", to: self.stackView)
    }

    @objc func tappedInView() {
        self.stackView.arrangedSubviews.forEach { view in
            if let view = view as? BaseSettingView {
                view.cancel()
            }
        }
    }
}
