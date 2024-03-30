//
//  TabBarViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 2/15/24.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    let userId: String
    let settingsStorage: SettingsStorage
    let api: API
    let siteInteractor: SiteInteractor
    
    lazy var puzzleListViewController: PuzzleListViewController = PuzzleListViewController(userId: self.userId,
                                                                                           settingsStorage: self.settingsStorage,
                                                                                           api: self.api,
                                                                                           siteInteractor: self.siteInteractor)
    lazy var puzzleListNavigationController: UINavigationController = {
        let nav = UINavigationController(rootViewController: self.puzzleListViewController)
        nav.tabBarItem = UITabBarItem(title: "Puzzles", image: UIImage(systemName: "cross"), tag: 0)
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }()

    lazy var settingsViewController: SettingsViewController = SettingsViewController(settingsStorage: self.settingsStorage)
    lazy var settingsNavigationController: UINavigationController = {
        let nav = UINavigationController(rootViewController: self.settingsViewController)
        nav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 1)
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }()

    lazy var sharedWithYouViewController: SharedWithYouViewController = SharedWithYouViewController(userId: self.userId,
                                                                                                    siteInteractor: self.siteInteractor,
                                                                                                    api: self.api,
                                                                                                    settingsStorage: self.settingsStorage)
    lazy var sharedWithYouNavigationController: UINavigationController = {
        let nav = UINavigationController(rootViewController: self.sharedWithYouViewController)
        nav.tabBarItem = UITabBarItem(title: "Shared", image: UIImage(systemName: "shared.with.you"), tag: 0)
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }()

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(userId: String, settingsStorage: SettingsStorage, api: API, siteInteractor: SiteInteractor) {
        self.userId = userId
        self.settingsStorage = settingsStorage
        self.api = api
        self.siteInteractor = siteInteractor
        super.init(nibName: nil, bundle: nil)
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        self.tabBar.scrollEdgeAppearance = tabBarAppearance
        
        self.viewControllers = [
            self.puzzleListNavigationController,
            self.sharedWithYouNavigationController,
            self.settingsNavigationController
        ]
    }
    
}
