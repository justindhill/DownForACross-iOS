//
//  PuzzleViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit
import WebKit
import Lottie

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
    
    lazy var swipeGestureRecognizer: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(toggleSidebar))
        gesture.delegate = self
        gesture.direction = .left
        return gesture
    }()
     
    var sideBarViewController: PuzzleSideBarViewController!
    var sideBarTapToDismissView: UIView!
    var sideBarLeadingConstraint: NSLayoutConstraint!
    lazy var sideBarTapToDismissGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleSidebar))
        return tap
    }()
    
    var newMessageStackView: PuzzleNewMessageStackView = PuzzleNewMessageStackView()
    var confettiView: LottieAnimationView?
    
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
        self.sideBarViewController = PuzzleSideBarViewController(puzzle: puzzleListEntry.content)
        self.sideBarTapToDismissView = UIView()
        self.sideBarTapToDismissView.translatesAutoresizingMaskIntoConstraints = false
        self.sideBarTapToDismissView.isUserInteractionEnabled = false
        super.init(nibName: nil, bundle: nil)
        
        self.sideBarTapToDismissView.addGestureRecognizer(self.sideBarTapToDismissGestureRecognizer)
        
        self.sideBarViewController.clueListViewController.delegate = self
        
        NotificationCenter.default.addObserver(forName: UIControl.keyboardWillShowNotification, object: nil, queue: nil) { note in
            guard let userInfo = note.userInfo else { return }
            let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
            self.currentKeyboardHeight = keyboardSize.height
        }
        
        NotificationCenter.default.addObserver(forName: UIControl.keyboardWillHideNotification, object: nil, queue: nil) { note in
            self.currentKeyboardHeight = 0
        }
        
        let copyItem = UIBarButtonItem(image: UIImage(systemName: "doc.on.doc"),
                                                      style: .plain,
                                                      target: self,
                                                      action: #selector(copyGameURLToPasteboard))
        let sideBarToggleItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.right"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(toggleSidebar))
        self.navigationItem.rightBarButtonItems = [copyItem, sideBarToggleItem]
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = .systemBackground
        self.view.addGestureRecognizer(self.swipeGestureRecognizer)

        self.puzzleView = PuzzleView(puzzleGrid: puzzle.grid)
        self.puzzleView.translatesAutoresizingMaskIntoConstraints = false
        self.puzzleView.delegate = self
        
        self.keyboardToolbar = PuzzleToolbarView()
        self.keyboardToolbar.translatesAutoresizingMaskIntoConstraints = false
        self.puzzleView(self.puzzleView, userCursorDidMoveToClueIndex: 1, sequenceIndex: 0, direction: self.puzzleView.userCursor.direction)
        
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
        
        self.view.addSubview(self.sideBarTapToDismissView)
        
        self.newMessageStackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.newMessageStackView)
        
        self.sideBarViewController.willMove(toParent: self)
        self.addChild(self.sideBarViewController)
        self.view.addSubview(self.sideBarViewController.view)
        self.sideBarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.sideBarViewController.didMove(toParent: self)
        
        self.sideBarLeadingConstraint = self.sideBarViewController.view.leadingAnchor.constraint(equalTo: self.view.trailingAnchor)

        NSLayoutConstraint.activate([
            self.puzzleView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.puzzleView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.puzzleView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.puzzleView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.keyboardToolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.keyboardToolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.keyboardToolbarBottomConstraint,
            self.sideBarViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.sideBarViewController.view.bottomAnchor.constraint(equalTo: self.keyboardToolbar.topAnchor),
            self.sideBarViewController.view.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.67),
            self.sideBarLeadingConstraint,
            self.sideBarTapToDismissView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.sideBarTapToDismissView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.sideBarTapToDismissView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.sideBarTapToDismissView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.newMessageStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.67),
            self.newMessageStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.newMessageStackView.bottomAnchor.constraint(equalTo: self.keyboardToolbar.topAnchor, constant: -8)
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
    
    @objc func toggleSidebar() {
        if self.sideBarLeadingConstraint.constant == 0 {
            self.sideBarLeadingConstraint.constant = -self.sideBarViewController.view.frame.size.width
            self.sideBarTapToDismissView.isUserInteractionEnabled = true
        } else {
            self.sideBarLeadingConstraint.constant = 0
            self.sideBarTapToDismissView.isUserInteractionEnabled = false
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func playConfettiAnimation() {
        if self.confettiView != nil {
            return
        }
        
        let lottieView = LottieAnimationView(name: "confetti")
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        lottieView.isUserInteractionEnabled = false
        self.confettiView = lottieView
        guard let puzzleViewIndex = self.view.subviews.firstIndex(of: self.puzzleView) else { return }
        self.view.insertSubview(lottieView, at: puzzleViewIndex + 1)
        
        NSLayoutConstraint.activate([
            lottieView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            lottieView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            lottieView.topAnchor.constraint(equalTo: self.view.topAnchor),
            lottieView.bottomAnchor.constraint(equalTo: self.keyboardToolbar.topAnchor)
        ])
        
        self.view.layoutIfNeeded()
        
        lottieView.play { [weak self] completed in
            lottieView.removeFromSuperview()
            self?.confettiView = nil
        }
    }
}

extension PuzzleViewController: GameClientDelegate {
    
    func gameClient(_ client: GameClient, didReceiveNewChatMessage message: ChatEvent, from: Player) {
        self.newMessageStackView.addChatMessage(message, from: from)
    }
    
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]], isSolved: Bool) {
        self.puzzleView.solution = solution
        
        if isSolved {
            self.playConfettiAnimation()
        }
    }
    
    func gameClient(_ client: GameClient, cursorsDidChange cursors: [String: Cursor]) {
        self.puzzleView.cursors = cursors.filter({ $0.key != self.userId })
    }
    
}

extension PuzzleViewController: PuzzleViewDelegate {
    
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToClueIndex clueIndex: Int, sequenceIndex: Int, direction: Direction) {
        switch direction {
            case .across:
                self.keyboardToolbar.clueLabel.text = self.puzzle.clues.across[clueIndex]
            case .down:
                self.keyboardToolbar.clueLabel.text = self.puzzle.clues.down[clueIndex]
        }
        
        self.sideBarViewController.clueListViewController.selectClue(atSequenceIndex: sequenceIndex, direction: direction)
    }
    
    func puzzleView(_ puzzleView: PuzzleView, didEnterText text: String?, atCoordinates coordinates: CellCoordinates) {
        self.gameClient.enter(value: text, atCoordinates: coordinates)
    }
    
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToCoordinates coordinates: CellCoordinates) {
        self.gameClient.moveUserCursor(to: coordinates)
    }
    
}


extension PuzzleViewController: PuzzleClueListViewControllerDelegate {
    
    func clueListViewController(_ clueListViewController: PuzzleClueListViewController, didSelectClueAtSequenceIndex sequenceIndex: Int, direction: Direction) {
        self.puzzleView.moveUserCursorToWord(atSequenceIndex: sequenceIndex, direction: direction)
    }
    
}

extension PuzzleViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self.view)
        let width: CGFloat = 10
        let activationArea = CGRect(x: self.view.frame.size.width - width,
                                    y: 0,
                                    width: width,
                                    height: self.view.frame.size.height)
        
        return activationArea.contains(location)
    }
    
}
