//
//  TabBarViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 2/15/24.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    let settingsStorage: SettingsStorage = SettingsStorage()
    lazy var puzzleListViewController: PuzzleListViewController = PuzzleListViewController(settingsStorage: self.settingsStorage)
    lazy var settingsViewController: SettingsViewController = SettingsViewController(settingsStorage: self.settingsStorage)
    lazy var puzzleListNavigationController: UINavigationController = {
        let nav = UINavigationController(rootViewController: self.puzzleListViewController)
        nav.tabBarItem = UITabBarItem(title: "Puzzles", image: UIImage(systemName: "cross"), tag: 0)
        return nav
    }()
    
    lazy var settingsNavigationController: UINavigationController = {
        let nav = UINavigationController(rootViewController: self.settingsViewController)
        nav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 1)
        return nav
    }()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [
            self.puzzleListNavigationController,
            self.settingsNavigationController
        ]
    }
    
}
