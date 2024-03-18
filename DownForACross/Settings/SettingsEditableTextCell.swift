//
//  SettingsEditableTextCell.swift
//  DownForACross
//
//  Created by Justin Hill on 3/18/24.
//

import UIKit

class SettingsEditableTextCell: SettingsBaseCell {

    private var textField: UITextField
    private var constraintsSetup: Bool = false

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textField = UITextField()
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.textAlignment = .right
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.textField)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if !self.constraintsSetup, let contentView = self.contentView as? UIListContentView, let textLayoutGuide = contentView.textLayoutGuide {
            self.constraintsSetup = true
            NSLayoutConstraint.activate([
                self.textField.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
                self.textField.centerYAnchor.constraint(equalTo: textLayoutGuide.centerYAnchor),
                self.textField.leadingAnchor.constraint(equalTo: textLayoutGuide.trailingAnchor, constant: 8),
                self.textField.heightAnchor.constraint(equalTo: textLayoutGuide.heightAnchor)
            ])
        }
    }

    var keyPath: WritableKeyPath<SettingsStorage, String>! {
        didSet {
            self.textField.text = self.settingsStorage[keyPath: keyPath]
        }
    }

    func set() {
        if let newValue = self.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), newValue.count > 0 {
            self.settingsStorage[keyPath: self.keyPath] = newValue
        } else {
            self.textField.text = self.settingsStorage[keyPath: self.keyPath]
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)

        guard let key = presses.first?.key?.keyCode else { return }
        switch key {
            case .keyboardReturnOrEnter:
                self.textField.resignFirstResponder()
                self.set()
            default:
                break
        }
    }

}
