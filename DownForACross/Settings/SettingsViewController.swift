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

    enum Mode {
        case root
        case appearance

        var title: String {
            switch self {
                case .root: "Settings"
                case .appearance: "Appearance"
            }
        }
    }

    let stackView: UIStackView
    let scrollView: UIScrollView
    let settingsStorage: SettingsStorage
    let mode: Mode

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(mode: Mode = .root, settingsStorage: SettingsStorage) {
        self.mode = mode
        self.settingsStorage = settingsStorage
        self.stackView = UIStackView()
        self.stackView.axis = .vertical
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView = UIScrollView()
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.alwaysBounceVertical = true
        super.init(nibName: nil, bundle: nil)

        self.navigationItem.title = self.mode.title
    }

    override func viewDidLoad() {
        self.view.backgroundColor = .systemGroupedBackground
        self.stackView.backgroundColor = .secondarySystemGroupedBackground
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.stackView)
        self.stackView.layer.cornerCurve = .continuous
        self.stackView.layer.cornerRadius = 12
        self.stackView.layer.masksToBounds = true
        self.stackView.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedInView))
        self.view.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            self.scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor, constant: 4),
            self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            self.stackView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -4),
            self.scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: self.view.widthAnchor),
        ])

        switch self.mode {
            case .root: self.addRootContent()
            case .appearance: self.addAppearanceContent()
        }
    }

    func addAppearanceContent() {
        self.addSetting(ColorSettingView(
            title: "Cursor color",
            details: "The color that will represent you to other players",
            settingsStorage: self.settingsStorage,
            keyPath: \.userDisplayColor))

        self.addSetting(ColorSettingView(
            title: "Pencil color",
            details: "The color that will be used to fill letters in pencil mode",
            settingsStorage: self.settingsStorage,
            keyPath: \.pencilColor))

        self.addSetting(SingleSelectSettingView(
            title: "App theme",
            settingsStorage: self.settingsStorage,
            keyPath: \.appearanceStyle,
            updateHandler: { newValue in
                guard let window = self.view.window else { return }
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                    window.overrideUserInterfaceStyle = newValue.userInterfaceStyle
                }
            })
        )

        self.addSetting(SwitchSettingView(
            title: "Unread messages badge",
            details: "Show a badge when there are chat messages you haven't seen yet",
            settingsStorage: self.settingsStorage,
            keyPath: \.showUnreadMessageBadges))

        self.addSetting(SwitchSettingView(
            title: "Chat message previews",
            details: "Show a message preview over the puzzle when new messages are received",
            settingsStorage: self.settingsStorage,
            keyPath: \.showMessagePreviews))

        self.addSetting(SwitchSettingView(title: "Show timer in navigation bar",
                                          settingsStorage: self.settingsStorage,
                                          keyPath: \.showTimerInNavigationBar))
    }

    func addRootContent() {
        self.addSetting(EditableTextSettingView(
            title: "Display name",
            details: "The name that will appear to other players in chat messages and the player list",
            settingsStorage: self.settingsStorage,
            keyPath: \.userDisplayName))

        self.addSetting(NavigationSettingView(
            title: "Appearance",
            details: nil,
            mode: .appearance,
            navigationHandler: self))

        self.addSetting(NavigationSettingView(
            title: "Quick filters",
            details: nil,
            handler: { [weak self] in
                self?.showQuickFiltersSettings()
            }))

        self.addSetting(SingleSelectSettingView(
            title: "Default input mode",
            details: "The input mode that will be initially selected when you start a game",
            settingsStorage: self.settingsStorage,
            keyPath: \.defaultInputMode))

        self.addSetting(SwitchSettingView(
            title: "Skip filled squares",
            details: "When moving the cursor, skip over cells that have been filled if they haven't been checked for correctness",
            settingsStorage: self.settingsStorage,
            keyPath: \.skipFilledCells))
    }

    func addSetting(_ view: UIView) {
        if self.stackView.arrangedSubviews.count > 0 {
            self.stackView.addArrangedSubview(Separator())
        }

        self.stackView.addArrangedSubview(view)
    }

    @objc func tappedInView() {
        self.stackView.arrangedSubviews.forEach { view in
            if let view = view as? BaseSettingView {
                view.cancel()
            }
        }
    }

    func showQuickFiltersSettings() {
        let vc = QuickFiltersViewController(settingsStorage: self.settingsStorage)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension SettingsViewController: NavigationSettingViewHandler {

    func navigationViewDidNavigateWithMode(mode: Mode) {
        let settingsVc = SettingsViewController(mode: mode, settingsStorage: self.settingsStorage)
        self.navigationController?.pushViewController(settingsVc, animated: true)
    }

}
