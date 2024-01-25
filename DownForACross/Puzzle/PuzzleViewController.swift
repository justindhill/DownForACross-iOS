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
    var keyboardToolbar: PuzzleToolbarView!
    var keyboardToolbarBottomConstraint: NSLayoutConstraint!
    var currentKeyboardHeight: CGFloat = 0 {
        didSet {
            self.view.setNeedsLayout()
        }
    }
    
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
        
        NotificationCenter.default.addObserver(forName: UIControl.keyboardWillShowNotification, object: nil, queue: nil) { note in
            guard let userInfo = note.userInfo else { return }
            let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
            self.currentKeyboardHeight = keyboardSize.height
        }
        
        NotificationCenter.default.addObserver(forName: UIControl.keyboardWillHideNotification, object: nil, queue: nil) { note in
            self.currentKeyboardHeight = 0
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "doc.on.doc"), 
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(copyGameURLToPasteboard))
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = .systemBackground

        self.puzzleView = PuzzleView(puzzleGrid: puzzle.grid)
        self.puzzleView.translatesAutoresizingMaskIntoConstraints = false
        self.puzzleView.delegate = self
        
        self.keyboardToolbar = PuzzleToolbarView()
        self.keyboardToolbar.translatesAutoresizingMaskIntoConstraints = false
        self.puzzleView(self.puzzleView, userCursorDidMoveToClueIndex: 1, direction: self.puzzleView.userCursor.direction)
        
        self.keyboardToolbar.leftButton.addAction(UIAction(handler: { [weak self] _ in
            self?.puzzleView.retreatUserCursorToPreviousWord()
        }), for: .primaryActionTriggered)
        
        self.keyboardToolbar.rightButton.addAction(UIAction(handler: { [weak self] _ in
            self?.puzzleView.advanceUserCursorToNextWord()
        }), for: .primaryActionTriggered)
        
        self.navigationItem.title = self.puzzle.info.title
        
        self.view.addSubview(self.puzzleView)
        self.view.addSubview(self.keyboardToolbar)
        
        self.keyboardToolbarBottomConstraint = self.keyboardToolbar.bottomAnchor.constraint(equalTo: self.view.keyboardLayoutGuide.topAnchor)

        NSLayoutConstraint.activate([
            self.puzzleView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.puzzleView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.puzzleView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.puzzleView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.keyboardToolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.keyboardToolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.keyboardToolbarBottomConstraint
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.additionalSafeAreaInsets.bottom = self.currentKeyboardHeight - self.view.safeAreaInsets.bottom
        self.puzzleView.scrollView.contentInset.bottom =
            self.keyboardToolbar.frame.size.height - self.keyboardToolbar.contentView.layoutMargins.bottom
        
        if self.currentKeyboardHeight == 0 {
            self.keyboardToolbar.layoutMargins.bottom = self.view.safeAreaInsets.bottom
            self.keyboardToolbarBottomConstraint.constant = self.view.safeAreaInsets.bottom
        } else {
            self.keyboardToolbar.layoutMargins.bottom = 0
            self.keyboardToolbarBottomConstraint.constant = 0
        }
    }
    
    var interactable: Bool {
        get { self.puzzleView.isUserInteractionEnabled }
        set {
            self.puzzleView.isUserInteractionEnabled = newValue
            self.puzzleView.alpha = newValue ? 1 : 0.5
        }
    }
    
    @objc func copyGameURLToPasteboard() {
        let urlString = "https://downforacross.com/beta/game/\(self.gameClient.gameId)"
        UIPasteboard.general.url = URL(string: urlString)!
    }
}

extension PuzzleViewController: GameClientDelegate {
    
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]]) {
        self.puzzleView.solution = solution
    }
    
    func gameClient(_ client: GameClient, cursorsDidChange cursors: [String: CellCoordinates], colors: [String: UIColor]) {
        self.puzzleView.cursors = cursors.filter({ $0.key != self.userId })
        self.puzzleView.cursorColors = colors.filter({ $0.key != self.userId })
    }
    
}

extension PuzzleViewController: PuzzleViewDelegate {
    
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToClueIndex clueIndex: Int, direction: PuzzleView.Direction) {
        print(self.puzzle.clues.down)
        switch direction {
            case .across:
                self.keyboardToolbar.clueLabel.text = self.puzzle.clues.across[clueIndex]
            case .down:
                self.keyboardToolbar.clueLabel.text = self.puzzle.clues.down[clueIndex]
        }
    }
    
    func puzzleView(_ puzzleView: PuzzleView, didEnterText text: String?, atCoordinates coordinates: CellCoordinates) {
        self.gameClient.enter(value: text, atCoordinates: coordinates)
    }
    
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToCoordinates coordinates: CellCoordinates) {
        self.gameClient.moveUserCursor(to: coordinates)
    }
    
}
