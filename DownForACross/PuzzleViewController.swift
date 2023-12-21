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
    let gameClient = GameClient()
    
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
