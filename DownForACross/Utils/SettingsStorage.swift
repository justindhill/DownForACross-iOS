//
//  SettingsStorage.swift
//  DownForACross
//
//  Created by Justin Hill on 2/15/24.
//

import UIKit

class SettingsStorage {
    
    @UserDefaultsOptionalEntry<String>(key: "userDisplayName")
    var userDisplayName
    
    @UserDefaultsOptionalArchiveEntry<UIColor>(key: "userDisplayColor")
    var userDisplayColor
    
    @UserDefaultsEntry<PuzzleListQuickFilterBarView.PuzzleSize>(key: "puzzleSizeFilter")
    var puzzleListSizeFilter = .all
    
    @UserDefaultsEntry<String>(key: "puzzleTextFilter")
    var puzzleTextFilter = ""
    
}
