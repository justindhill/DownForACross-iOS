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

    @UserDefaultsArchiveEntry<UIColor>(key: "pencilColor")
    var pencilColor = UIColor.systemTeal

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

    @UserDefaultsEntry<Bool>(key: "skipFilledCells")
    var skipFilledCells = true

    @UserDefaultsEntry<Bool>(key: "showUnreadMessageBadges")
    var showUnreadMessageBadges = true

    @UserDefaultsEntry<Bool>(key: "showMessagePreviews")
    var showMessagePreviews = true

    @UserDefaultsEntry<[String: String]>(key: "puzzleIdToGameIdMap")
    var puzzleIdToGameIdMap = [:]

    @UserDefaultsEntry<[String: GameClient.SolutionState]>(key: "gameIdToCompletionMap")
    var gameIdToCompletion = [:]

    var onboardingComplete: Bool {
        get { self.onboardingVersionComplete == self.currentOnboardingVersion }
    }
    
    func setOnboardingComplete() {
        self.onboardingVersionComplete = self.currentOnboardingVersion
    }

    func runMigrations() {
        let createdGameKey = "com.justinhill.DownForACross.puzzleIdToCreatedGameMap"
        if let createdGamesData = UserDefaults.standard.object(forKey: createdGameKey) as? Data,
           let createdGames = try? JSONDecoder().decode([String: PuzzleListCreatedGame].self, from: createdGamesData) {
            var pidToGid: [String: String] = [:]
            var gidToCompletion: [String: GameClient.SolutionState] = [:]

            createdGames.forEach { (key, value) in
                pidToGid[key] = value.gameId
                gidToCompletion[value.gameId] = value.completion
            }

            self.puzzleIdToGameIdMap = pidToGid
            self.gameIdToCompletion = gidToCompletion
            UserDefaults.standard.removeObject(forKey: createdGameKey)
        }
    }
}
