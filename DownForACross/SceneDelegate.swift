//
//  SceneDelegate.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    static let userIdUserDefaultsKey: String = "UserId"
    
    var window: UIWindow?
    let api: API = API()
    let siteInteractor: SiteInteractor = SiteInteractor()
    let settingsStorage: SettingsStorage = SettingsStorage()
    var joinGameCoordinator: JoinGameCoordinator?

    lazy var launchInterstitialViewController: LaunchInterstitialViewController = LaunchInterstitialViewController()
    lazy var onboardingViewController: OnboardingViewController = {
        let viewController = OnboardingViewController(settingsStorage: self.settingsStorage)
        viewController.delegate = self
        return viewController
    }()
    var tabBarViewController: TabBarViewController?
    var pendingUserActivity: NSUserActivity?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }

        self.pendingUserActivity = connectionOptions.userActivities.first

        self.window = UIWindow(windowScene: scene)
        self.window?.rootViewController = UIViewController()
        self.window?.isHidden = false
        
        self.window?.overrideUserInterfaceStyle = self.settingsStorage.appearanceStyle.userInterfaceStyle
        self.resolveLaunchRequirementsAndLaunch()
    }
    
    func resolveLaunchRequirementsAndLaunch() {
        if let userId = self.settingsStorage.userId {
            print("got a user id from UserDefaults!")
            if self.settingsStorage.onboardingComplete {
                self.showTabBarController(userId: userId)
            } else {
                self.showOnboarding()
            }
        } else {
            self.showLaunchInterstitial()
            self.siteInteractor.getUserId { [weak self] userId in
                guard let self else { return }
                if let userId {
                    print("got a user id from the site!")
                    self.settingsStorage.userId = userId
                    if self.settingsStorage.onboardingComplete {
                        self.showTabBarController(userId: userId)
                    } else {
                        self.showOnboarding()
                    }
                } else {
                    print("failed to get a user id from the site")
                }
            }
        }
    }
    
    func showOnboarding() {
        self.hideViewController(self.launchInterstitialViewController)
        self.showViewController(self.onboardingViewController)
    }
    
    func showLaunchInterstitial() {
        self.showViewController(self.launchInterstitialViewController)
    }
    
    func showTabBarController(userId: String) {
        self.hideViewController(self.launchInterstitialViewController)
        
        let tabBarViewController = TabBarViewController(userId: userId,
                                                        settingsStorage: self.settingsStorage,
                                                        api: self.api,
                                                        siteInteractor: self.siteInteractor)
        self.tabBarViewController = tabBarViewController
        self.showViewController(tabBarViewController)

        if let userActivity = self.pendingUserActivity {
            self.pendingUserActivity = nil
            self.continueUserActivity(userActivity)
        }
    }
    
    func showViewController(_ viewController: UIViewController) {
        guard let container = self.window?.rootViewController else { return }

        viewController.willMove(toParent: container)
        container.view.addSubview(viewController.view)
        container.addChild(viewController)
        viewController.didMove(toParent: container)
    }
    
    func hideViewController(_ viewController: UIViewController) {
        guard viewController.parent != nil else { return }
        
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.didMove(toParent: nil)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        self.continueUserActivity(userActivity)
    }

    func continueUserActivity(_ userActivity: NSUserActivity) {
        guard let navigationController = self.tabBarViewController?.puzzleListNavigationController,
              let userId = self.settingsStorage.userId else { return }

        let gameId = userActivity.webpageURL!.lastPathComponent

        self.tabBarViewController?.selectedIndex = 0
        self.joinGameCoordinator = JoinGameCoordinator(navigationController: navigationController,
                                                       gameId: gameId,
                                                       userId: userId,
                                                       api: self.api,
                                                       siteInteractor: self.siteInteractor,
                                                       settingsStorage: self.settingsStorage)
        self.joinGameCoordinator?.start()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        
        if url.host() == "game" {
            Task {
                do {
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let name = components.queryItems?.first(where: { $0.name == "name" })?.value,
                          let puzzleId = components.queryItems?.first(where: { $0.name == "puzzleId" })?.value,
                          let gameId = components.queryItems?.first(where: { $0.name == "gameId" })?.value else {
                        print("URL didn't have the appropriate structure")
                        return
                    }
                    
                    guard let puzzleListEntry = try await self.api.findPuzzle(name: name, id: puzzleId) else {
                        print("Couldn't find a puzzle with id \"\(puzzleId)\" named \"\(name)\"")
                        return
                    }
                    
                    self.tabBarViewController?.puzzleListViewController.show(puzzleListEntry: puzzleListEntry, gameId: gameId)
                } catch {
                    
                }
            }
        }
    }
}

extension SceneDelegate: OnboardingViewControllerDelegate {
    
    func onboardingViewControllerDidComplete(_ onboardingViewController: OnboardingViewController) {
        guard let userId = self.settingsStorage.userId else { fatalError("Onboarding completed before a user ID was resolved") }
        self.window?.overrideUserInterfaceStyle = self.settingsStorage.appearanceStyle.userInterfaceStyle
        self.showTabBarController(userId: userId)
    }
    
}

