//
//  PuzzleViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit

class PuzzleViewController: UIViewController {
    
    let puzzle: Puzzle
    var puzzleView: PuzzleView!
    lazy var gameClient: GameClient = {
        let client = GameClient(puzzle: self.puzzle)
        client.delegate = self
        return client
    }()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        self.gameClient.connect()
        self.view.backgroundColor = .systemBackground

        self.puzzleView = PuzzleView(puzzleGrid: puzzle.grid)
        self.puzzleView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.puzzleView)

        NSLayoutConstraint.activate([
            self.puzzleView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.puzzleView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.puzzleView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.puzzleView.heightAnchor.constraint(equalTo: self.puzzleView.widthAnchor)
        ])
        
    }
    
}

extension PuzzleViewController: GameClientDelegate {
    
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]]) {
        self.puzzleView.solution = solution
    }
    
    func gameClient(_ client: GameClient, cursorsDidChange cursors: [String: CellCoordinates]) {
        self.puzzleView.cursors = cursors
    }
    
}
