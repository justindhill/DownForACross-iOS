//
//  PuzzleViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit
import WebKit

class PuzzleViewController: UIViewController {
    
    let puzzle: Puzzle
    let puzzleId: String
    let userId: String
    let siteInteractor: SiteInteractor
    let api: API
    
    var puzzleView: PuzzleView!
    lazy var gameClient: GameClient = {
        let client = GameClient(puzzle: self.puzzle, userId: self.userId)
        client.delegate = self
        return client
    }()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(puzzleListEntry: PuzzleListEntry, userId: String, siteInteractor: SiteInteractor, api: API) {
        self.puzzle = puzzleListEntry.content
        self.puzzleId = puzzleListEntry.pid
        self.userId = userId
        self.siteInteractor = siteInteractor
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = .systemBackground

        self.puzzleView = PuzzleView(puzzleGrid: puzzle.grid)
        self.puzzleView.translatesAutoresizingMaskIntoConstraints = false
        self.puzzleView.delegate = self
        self.navigationItem.title = self.puzzle.info.title
        self.view.addSubview(self.puzzleView)

        NSLayoutConstraint.activate([
            self.puzzleView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.puzzleView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.puzzleView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
        ])
        
        self.interactable = false
        self.siteInteractor.createGame(puzzleId: self.puzzleId) { gameId in
            self.gameClient.connect(gameId: gameId)
            self.interactable = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.puzzleView.becomeFirstResponder()
    }
    
    var interactable: Bool {
        get { self.puzzleView.isUserInteractionEnabled }
        set {
            self.puzzleView.isUserInteractionEnabled = newValue
            self.puzzleView.alpha = newValue ? 1 : 0.5
        }
    }
}

extension PuzzleViewController: GameClientDelegate {
    
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]]) {
        self.puzzleView.solution = solution
    }
    
    func gameClient(_ client: GameClient, cursorsDidChange cursors: [String: CellCoordinates]) {
        self.puzzleView.cursors = cursors.filter({ $0.key != self.userId })
    }
    
}

extension PuzzleViewController: PuzzleViewDelegate {
    
    func puzzleView(_ puzzleView: PuzzleView, didEnterText text: String?, atCoordinates coordinates: CellCoordinates) {
        self.gameClient.enter(value: text, atCoordinates: coordinates)
    }
    
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToCoordinates coordinates: CellCoordinates) {
        self.gameClient.moveUserCursor(to: coordinates)
    }
    
}
