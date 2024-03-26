//
//  OnboardingViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 3/1/24.
//

import UIKit

protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingViewControllerDidComplete(_ onboardingViewController: OnboardingViewController)
}

class OnboardingViewController: UIViewController {
    
    weak var delegate: OnboardingViewControllerDelegate?
    
    lazy var appearanceModeSelector: UISegmentedControl = {
        let control = UISegmentedControl(items: ["System", "Light", "Dark"])
        control.selectedSegmentIndex = self.settingsStorage.appearanceStyle.rawValue
        control.addTarget(self, action: #selector(appearanceSelectorDidChange), for: .valueChanged)
        return control
    }()
    
    lazy var continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Continue"
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(continueButtonTapped), for: .primaryActionTriggered)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return button
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "How do you want to appear to other players?"
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.numberOfLines = 0
        
        return label
    }()
    
    let otherPreferencesLabel: UILabel = {
        let label = UILabel()
        label.text = "Other preferences"
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.numberOfLines = 0
        
        return label
    }()
    
    let displayNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        
        return label
    }()
    
    let appearanceLabel: UILabel = {
        let label = UILabel()
        label.text = "Theme"
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        
        return label
    }()
    
    lazy var displayNameTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
        textField.text = self.settingsStorage.userDisplayName
        
        return textField
    }()
    
    let cursorColorLabel: UILabel = {
        let label = UILabel()
        label.text = "Cursor color"
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        
        return label
    }()
    lazy var colorPickerView: ColorPickerView = {
        let view = ColorPickerView()
        view.addTarget(self, action: #selector(selectedColorDidChange), for: .valueChanged)
        
        return view
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = true
        
        return stackView
    }()
    
    let settingsStorage: SettingsStorage
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(settingsStorage: SettingsStorage) {
        self.settingsStorage = settingsStorage
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.stackView)
        self.view.addSubview(self.continueButton)
        self.view.backgroundColor = .systemBackground
        self.additionalSafeAreaInsets.top = 32
        
        self.colorPickerView.setSelectedColorToMatchingColorIfPossible(self.settingsStorage.userDisplayColor)
        
        self.stackView.addArrangedSubview(self.titleLabel)
        self.stackView.setCustomSpacing(16, after: self.titleLabel)
        self.stackView.addArrangedSubview(self.displayNameLabel)
        self.stackView.setCustomSpacing(4, after: self.displayNameLabel)
        self.stackView.addArrangedSubview(self.displayNameTextField)
        self.stackView.setCustomSpacing(16, after: self.displayNameTextField)
        self.stackView.addArrangedSubview(self.cursorColorLabel)
        self.stackView.setCustomSpacing(4, after: self.cursorColorLabel)
        self.stackView.addArrangedSubview(self.colorPickerView)
        self.stackView.setCustomSpacing(32, after: self.colorPickerView)
        self.stackView.addArrangedSubview(self.otherPreferencesLabel)
        self.stackView.setCustomSpacing(16, after: self.otherPreferencesLabel)
        self.stackView.addArrangedSubview(self.appearanceLabel)
        self.stackView.setCustomSpacing(4, after: self.appearanceLabel)
        self.stackView.addArrangedSubview(self.appearanceModeSelector)
        
        NSLayoutConstraint.activate([
            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.stackView.bottomAnchor.constraint(lessThanOrEqualTo: self.continueButton.topAnchor, constant: -8),
            self.continueButton.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.continueButton.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            self.continueButton.bottomAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.continueButton.bottomAnchor.constraint(lessThanOrEqualTo: self.view.keyboardLayoutGuide.topAnchor, constant: -12)
        ])
        
        self.textFieldTextDidChange()
    }
    
    @objc func textFieldTextDidChange() {
        if let text = self.displayNameTextField.text, text.count > 0 {
            self.displayNameTextField.layer.borderColor = UIColor.systemGray5.cgColor
            self.settingsStorage.userDisplayName = text
            self.continueButton.isEnabled = true
        } else {
            self.displayNameTextField.layer.borderColor = UIColor.systemRed.cgColor
            self.continueButton.isEnabled = false
        }
    }
    
    @objc func appearanceSelectorDidChange() {
        guard let appearance = SettingsStorage.Appearance(rawValue: self.appearanceModeSelector.selectedSegmentIndex) else {
            return
        }
        
        self.settingsStorage.appearanceStyle = appearance

        guard let window = self.view.window else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.overrideUserInterfaceStyle = appearance.userInterfaceStyle
        }
    }
    
    @objc func continueButtonTapped() {
        self.settingsStorage.setOnboardingComplete()
        self.displayNameTextField.resignFirstResponder()
        self.delegate?.onboardingViewControllerDidComplete(self)
    }
    
    @objc func selectedColorDidChange() {
        let color = self.colorPickerView.selectedColor
        print()
        print(color)
        self.settingsStorage.userDisplayColor = color
        print(self.settingsStorage.userDisplayColor)
        
    }
    
}

extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
