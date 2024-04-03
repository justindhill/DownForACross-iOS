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
        textField.textColor = .secondaryLabel
        textField.returnKeyType = .done
        textField.delegate = self
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.bounds.contains(point) {
            return self.textField
        }

        return super.hitTest(point, with: event)
    }

    override func cancel() {
        self.textField.resignFirstResponder()
        self.textField.textColor = .secondaryLabel
        self.textField.text = self.settingsStorage[keyPath: keyPath]
    }

}

extension EditableTextSettingView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        textField.textColor = .secondaryLabel
        if let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            self.settingsStorage[keyPath: self.keyPath] = text
            textField.text = text
        } else {
            self.cancel()
        }
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = .label

        guard let text = textField.text else { return }

        DispatchQueue.main.async {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument,
                                                              to: textField.endOfDocument)
        }
    }
}
