//
//  SettingsStorage.swift
//  DownForACross
//
//  Created by Justin Hill on 2/15/24.
//

import UIKit

class SettingsStorage {
    
    enum Appearance: Int, Codable, SettingsDisplayable {
        case system
        case light
        case dark
        
        var userInterfaceStyle: UIUserInterfaceStyle {
            switch self {
                case .system: return .unspecified
                case .light: return .light
                case .dark: return .dark
            }
        }

        var displayString: String {
            switch self {
                case .system: "System"
                case .light: "Light"
                case .dark: "Dark"
            }
        }
    }
    
    private let currentOnboardingVersion: Int = 4

    @UserDefaultsEntry<String>(key: "userDisplayName")
    var userDisplayName = ""
    
    @UserDefaultsArchiveEntry<UIColor>(key: "userDisplayColor")
    var userDisplayColor = UIColor.systemPink
    
    @UserDefaultsEntry<PuzzleListQuickFilterBarView.PuzzleSize>(key: "puzzleSizeFilter")
    var puzzleListSizeFilter = .all
    
    @UserDefaultsEntry<String>(key: "puzzleTextFilter")
    var puzzleTextFilter = ""
    
    @UserDefaultsEntry<Int>(key: "onboardingVersionComplete")
    private var onboardingVersionComplete = 0
    
    @UserDefaultsOptionalEntry<String>(key: "userId")
    var userId
    
    @UserDefaultsEntry<Appearance>(key: "appearanceStyle")
    var appearanceStyle = .system
    
    @UserDefaultsEntry<GameClient.InputMode>(key: "defaultInputMode")
    var defaultInputMode = .normal

    @UserDefaultsEntry<Bool>(key: "hasSeenInputModeQuickswitchTooltip")
    var hasSeenInputModeQuickswitchTooltip = false

    @UserDefaultsEntry<[String: ResolvedSharedGame]>(key: "cachedSharedGameInfo")
    var cachedSharedGameInfo = [:]

    @UserDefaultsEntry<[RecentlyOpenedSharedGame]>(key: "recentlyOpenedSharedGames")
    var recentlyOpenedSharedGames = []

    var onboardingComplete: Bool {
        get { self.onboardingVersionComplete == self.currentOnboardingVersion }
    }
    
    func setOnboardingComplete() {
        self.onboardingVersionComplete = self.currentOnboardingVersion
    }
}
