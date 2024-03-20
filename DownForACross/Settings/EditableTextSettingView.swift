//
//  EditableTextSettingView.swift
//  DownForACross
//
//  Created by Justin Hill on 3/20/24.
//

import UIKit

class EditableTextSettingView: BaseSettingView {

    let textField: UITextField = {
        let textField = UITextField()
        return textField
    }()

    let keyPath: WritableKeyPath<SettingsStorage, String>

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(title: String, details: String?, settingsStorage: SettingsStorage, keyPath: WritableKeyPath<SettingsStorage, String>) {
        self.keyPath = keyPath
        super.init(title: title, details: details, settingsStorage: settingsStorage, accessoryView: self.textField)
        textField.text = settingsStorage[keyPath: keyPath]
        textField.returnKeyType = .done
        textField.delegate = self
    }

    override func cancel() {
        self.textField.resignFirstResponder()
        self.textField.text = self.settingsStorage[keyPath: keyPath]
    }

}

extension EditableTextSettingView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            self.settingsStorage[keyPath: self.keyPath] = text
            textField.text = text
        } else {
            self.cancel()
        }
        return false
    }
}
