//
//  SettingsStorage.swift
//  DownForACross
//
//  Created by Justin Hill on 2/15/24.
//

import UIKit

class SettingsStorage {
    
    @UserDefaultsEntry<String?>(key: "userDisplayName")
    var userDisplayName
    
    @UserDefaultsEntry<UIColor?>(key: "userDisplayColor")
    var userDisplayColor
    
    
}
