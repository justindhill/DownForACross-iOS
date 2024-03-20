//
//  SingleSelectSettingView.swift
//  DownForACross
//
//  Created by Justin Hill on 3/20/24.
//

import UIKit

class SingleSelectSettingView<T: SettingsDisplayable>: BaseSettingView {

    let keyPath: WritableKeyPath<SettingsStorage, T>
    let updateHandler: ((T) -> Void)?
    let button: UIButton = {
        let button = UIButton(configuration: .plain())
        button.showsMenuAsPrimaryAction = true
        button.configuration?.contentInsets = .zero
        button.tintColor = .label
        return button
    }()

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(title: String, details: String? = nil, settingsStorage: SettingsStorage, keyPath: WritableKeyPath<SettingsStorage, T>, updateHandler: ((T) -> Void)? = nil) {
        self.keyPath = keyPath
        self.updateHandler = updateHandler
        super.init(title: title, details: details, settingsStorage: settingsStorage, accessoryView: self.button)
        button.configuration?.attributedTitle = self.titleString(for: settingsStorage[keyPath: keyPath].displayString)
        
        button.menu = UIMenu(children: T.allCases.map({ value in
            UIAction(title: value.displayString) { action in
                self.button.configuration?.attributedTitle = self.titleString(for: value.displayString)
                self.settingsStorage[keyPath: self.keyPath] = value
                self.setNeedsLayout()
                self.layoutIfNeeded()
                self.updateHandler?(value)
            }
        }))
    }

    func titleString(for string: String) -> AttributedString {
        var attributedString = AttributedString(string + " ")
        let textAttachment = NSTextAttachment(image: UIImage(systemName: "chevron.down")!)
        let attachmentString = AttributedString("\(UnicodeScalar(NSTextAttachment.character)!)", attributes: AttributeContainer().attachment(textAttachment))
        attributedString += attachmentString

        return attributedString
    }

}

