//
//  JoinGameCoordinator.swift
//  DownForACross
//
//  Created by Justin Hill on 3/15/24.
//

import UIKit

class JoinGameCoordinator {

    var loadingViewController: UIViewController?
    var joinConfirmationViewController: JoinConfirmationViewController?
    let navigationController: UINavigationController
    let gameId: String
    let userId: String
    let api: API
    let siteInteractor: SiteInteractor
    let settingsStorage: SettingsStorage
    var gameClient: GameClient

    init(navigationController: UINavigationController,
         gameId: String,
         userId: String,
         api: API,
         siteInteractor: SiteInteractor,
         settingsStorage: SettingsStorage) {

        self.navigationController = navigationController
        self.gameId = gameId
        self.userId = userId
        self.settingsStorage = settingsStorage
        self.api = api
        self.siteInteractor = siteInteractor
        self.gameClient = GameClient(puzzle: Puzzle.empty(),
                                     puzzleId: "",
                                     userId: userId,
                                     gameId: gameId,
                                     settingsStorage: settingsStorage)
    }

    func start() {
        let loadingViewController = self.createLoadingViewController()
        self.loadingViewController = loadingViewController
        self.loadingViewController?.modalPresentationStyle = .overFullScreen
        self.navigationController.present(loadingViewController, animated: false)

        self.gameClient.defersJoining = true
        self.gameClient.delegate = self
        self.gameClient.connect()
    }

    func presentJoinSheet(puzzle: Puzzle, players: [Player]) {
        self.loadingViewController?.dismiss(animated: false) {
            self.loadingViewController = nil
            let viewController = JoinConfirmationViewController(puzzle: puzzle, players: players)
            viewController.delegate = self
            self.joinConfirmationViewController = viewController
            self.navigationController.present(viewController, animated: true)
        }
    }

    func createLoadingViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .white
        viewController.view.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])

        spinner.startAnimating()
        return viewController
    }

}

extension JoinGameCoordinator: GameClientDelegate {
    
    func gameClient(_ client: GameClient, newPlayerJoined player: Player) {
        // no-op
    }

    func gameClient(_ client: GameClient, cursorsDidChange cursors: [String : Cursor]) {
        // no-op
    }
    
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]], isBulkUpdate: Bool, isSolved: Bool) {
        // no-op
    }
    
    func gameClient(_ client: GameClient, didReceiveNewChatMessage message: ChatEvent, from: Player) {
        // no-op
    }
    
    func gameClient(_ client: GameClient, connectionStateDidChange connectionState: GameClient.ConnectionState) {
        switch connectionState {
            case .connecting, .disconnected, .syncing:
                break
            case .connected:
                if self.joinConfirmationViewController == nil {
                    self.presentJoinSheet(puzzle: client.puzzle, players: Array(client.players.values))
                }
        }
    }

}

extension JoinGameCoordinator: JoinConfirmationViewControllerDelegate {

    func joinConfirmationViewControllerDidSelectJoin(_ viewController: JoinConfirmationViewController) {
        self.joinConfirmationViewController = nil

        let puzzleViewController = PuzzleViewController(gameClient: gameClient,
                                                        siteInteractor: self.siteInteractor,
                                                        api: self.api,
                                                        settingsStorage: self.settingsStorage)

        self.navigationController.dismiss(animated: true)
        var viewControllers = [self.navigationController.viewControllers[0], puzzleViewController]
        self.navigationController.setViewControllers(viewControllers, animated: true)
    }

    func joinConfirmationViewControllerDidSelectClose(_ viewController: JoinConfirmationViewController) {
        self.joinConfirmationViewController = nil
        self.navigationController.dismiss(animated: true)
    }

}
