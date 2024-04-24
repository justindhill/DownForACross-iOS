//
//  SwitchSettingView.swift
//  DownForACross
//
//  Created by Justin Hill on 4/3/24.
//

import UIKit

class SwitchSettingView: BaseSettingView {

    var settingsStorage: SettingsStorage
    let switchView: UISwitch

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(title: String, details: String? = nil, settingsStorage: SettingsStorage, keyPath: WritableKeyPath<SettingsStorage, Bool>, updateHandler: ((Bool) -> Void)? = nil) {
        self.settingsStorage = settingsStorage
        self.switchView = UISwitch()
        super.init(title: title, details: details, accessoryView: self.switchView)

        self.switchView.isOn = self.settingsStorage[keyPath: keyPath]

        self.switchView.addAction(UIAction() { [weak self] _ in
            guard let self else { return }
            self.settingsStorage[keyPath: keyPath] = self.switchView.isOn
            updateHandler?(self.switchView.isOn)
        }, for: .valueChanged)
    }
    
}
