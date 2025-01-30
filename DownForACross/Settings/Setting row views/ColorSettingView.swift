//
//  SingleSelectSettingView.swift
//  DownForACross
//
//  Created by Justin Hill on 3/20/24.
//

import UIKit

class ColorSettingView: BaseSettingView {

    var settingsStorage: SettingsStorage
    let keyPath: WritableKeyPath<SettingsStorage, UIColor>
    let updateHandler: ((UIColor) -> Void)?
    let button: GreedyButton = {
        let button = GreedyButton(configuration: .plain())
        button.configuration?.contentInsets = .zero
        return button
    }()

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(title: String, details: String? = nil, settingsStorage: SettingsStorage, keyPath: WritableKeyPath<SettingsStorage, UIColor>, updateHandler: ((UIColor) -> Void)? = nil) {
        self.settingsStorage = settingsStorage
        self.keyPath = keyPath
        self.updateHandler = updateHandler
        super.init(title: title, details: details, accessoryView: self.button)
        button.configuration?.attributedTitle = self.titleString(color: settingsStorage[keyPath: keyPath])
        button.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            self.showColorPicker()
        }), for: .primaryActionTriggered)
    }

    func titleString(color: UIColor) -> AttributedString {
        var attributedString = self.textAttachmentString(systemImageName: "circle.fill", color: color)
        attributedString += " "
        attributedString += self.textAttachmentString(systemImageName: "chevron.down", color: .secondaryLabel)

        return attributedString
    }

    func textAttachmentString(systemImageName: String, color: UIColor) -> AttributedString {
        let image = UIImage(systemName: systemImageName)!
        let textAttachment = NSTextAttachment(image: image)
        let attachmentString = AttributedString("\(UnicodeScalar(NSTextAttachment.character)!)", attributes: AttributeContainer().attachment(textAttachment).foregroundColor(color))

        return attachmentString
    }

    func showColorPicker() {
        guard let currentViewController = self.closestViewController() else { return }

        let width = min(self.frame.size.width * (5/8), 240)

        let vc = ColorPickerViewController()
        vc.colorPickerView.addTarget(self, action: #selector(colorDidChange(_:)), for: .valueChanged)
        vc.preferredContentSize =  CGSize(width: width, height: 0)
        vc.popoverPresentationController?.sourceView = self.button
        currentViewController.present(vc, animated: true)
    }

    @objc func colorDidChange(_ sender: ColorPickerView) {
        self.settingsStorage[keyPath: self.keyPath] = sender.selectedColor
        self.button.configuration?.attributedTitle = self.titleString(color: sender.selectedColor)
        self.updateHandler?(sender.selectedColor)
        self.closestViewController()?.dismiss(animated: true)
    }

}
