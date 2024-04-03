//
//  SwitchSettingView.swift
//  DownForACross
//
//  Created by Justin Hill on 4/3/24.
//

import UIKit

class SwitchSettingView: BaseSettingView {

    let switchView: UISwitch

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(title: String, details: String?, settingsStorage: SettingsStorage, keyPath: WritableKeyPath<SettingsStorage, Bool>, updateHandler: ((Bool) -> Void)? = nil) {
        self.switchView = UISwitch()
        super.init(title: title, details: details, settingsStorage: settingsStorage, accessoryView: self.switchView)

        self.switchView.isOn = self.settingsStorage[keyPath: keyPath]

        self.switchView.addAction(UIAction() { [weak self] _ in
            guard let self else { return }
            self.settingsStorage[keyPath: keyPath] = self.switchView.isOn
            updateHandler?(self.switchView.isOn)
        }, for: .valueChanged)
    }
    
}
