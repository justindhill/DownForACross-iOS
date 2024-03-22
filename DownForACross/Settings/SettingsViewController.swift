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
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView = UIScrollView()
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.alwaysBounceVertical = true
        super.init(nibName: nil, bundle: nil)

        self.navigationItem.title = "Settings"
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

        self.updateContent()
    }

    func updateContent() {
        self.stackView.addArrangedSubview(EditableTextSettingView(
            title: "Display name",
            details: "How you will appear to other players in chat messages and the player list",
            settingsStorage: self.settingsStorage,
            keyPath: \.userDisplayName))

        self.addSetting(SingleSelectSettingView(
            title: "Default input mode",
            details: "The input mode that will be initiallly selected when you start a game",
            settingsStorage: self.settingsStorage,
            keyPath: \.defaultInputMode))

        self.addSetting(SingleSelectSettingView(
            title: "Theme",
            settingsStorage: self.settingsStorage,
            keyPath: \.appearanceStyle,
            updateHandler: { newValue in
                guard let window = self.view.window else { return }
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                    window.overrideUserInterfaceStyle = newValue.userInterfaceStyle
                }
            })
        )
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

    class Separator: UIView {
        let lineLayer: CALayer = CALayer()

        override func didMoveToWindow() {
            if let screen = self.window?.screen {
                self.heightConstraint.constant = 1 / screen.scale
            }
        }

        lazy var heightConstraint: NSLayoutConstraint = self.heightAnchor.constraint(equalToConstant: 1)

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override init(frame: CGRect) {
            super.init(frame: frame)

            self.layoutMargins = BaseSettingView.layoutMargins
            NSLayoutConstraint.activate([
                self.heightConstraint
            ])

            self.layer.addSublayer(self.lineLayer)
        }

        override func layoutSublayers(of layer: CALayer) {
            self.lineLayer.backgroundColor = UIColor.systemFill.cgColor
            self.lineLayer.frame = CGRect(x: self.layoutMargins.left,
                                          y: 0, 
                                          width: self.frame.size.width - self.layoutMargins.left,
                                          height: self.frame.size.height)
        }
    }
}
