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
    
    static let puzzleIdToGameIdMapUserDefaultsKey = "com.justinhill.DownForACross.puzzleIdToGameIdMap"
    
    let puzzle: Puzzle
    let puzzleId: String
    let userId: String
    let siteInteractor: SiteInteractor
    let api: API
    var puzzleIdToGameIdMap: [String: String] {
        didSet {
            UserDefaults.standard.setValue(puzzleIdToGameIdMap, forKey: Self.puzzleIdToGameIdMapUserDefaultsKey)
        }
    }
    
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
     
    var sideBarViewController: PuzzleSideBarViewController
    var sideBarTapToDismissView: UIView
    var sideBarLeadingConstraint: NSLayoutConstraint!
    lazy var sideBarTapToDismissGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleSidebar))
        return tap
    }()
    
    var newMessageStackView: PuzzleNewMessageStackView = PuzzleNewMessageStackView()
    var confettiView: LottieAnimationView?
    
    lazy var gameClient: GameClient = {
        let client = GameClient(puzzle: self.puzzle, userId: self.userId, gameId: self.puzzleIdToGameIdMap[self.puzzleId])
        client.delegate = self
        return client
    }()
    
    var isSidebarVisible: Bool {
        return self.sideBarLeadingConstraint.constant < 0
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(puzzleListEntry: PuzzleListEntry, userId: String, siteInteractor: SiteInteractor, api: API) {
        self.puzzle = puzzleListEntry.content
        self.puzzleId = puzzleListEntry.pid
        self.userId = userId
        self.siteInteractor = siteInteractor
        self.api = api
        self.sideBarViewController = PuzzleSideBarViewController(puzzle: puzzleListEntry.content)
        self.sideBarViewController.messagesViewController.selfUserId = userId
        self.sideBarTapToDismissView = UIView()
        self.sideBarTapToDismissView.translatesAutoresizingMaskIntoConstraints = false
        self.sideBarTapToDismissView.isUserInteractionEnabled = false
        
        if let gameIdMap = UserDefaults.standard.object(forKey: Self.puzzleIdToGameIdMapUserDefaultsKey) as? [String: String] {
            self.puzzleIdToGameIdMap = gameIdMap
        } else {
            self.puzzleIdToGameIdMap = [:]
        }
        
        super.init(nibName: nil, bundle: nil)
        
        self.sideBarViewController.delegate = self
        self.hidesBottomBarWhenPushed = true
        self.sideBarTapToDismissView.addGestureRecognizer(self.sideBarTapToDismissGestureRecognizer)
        
        self.sideBarViewController.clueListViewController.delegate = self
        
        NotificationCenter.default.addObserver(forName: UIControl.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] note in
            guard let self, let userInfo = note.userInfo else { return }
            let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
            self.currentKeyboardHeight = keyboardSize.height
            self.updateContentInsets()
        }
        
        NotificationCenter.default.addObserver(forName: UIControl.keyboardDidHideNotification, object: nil, queue: nil) { [weak self] note in
            guard let self else { return }
            self.currentKeyboardHeight = 0
            self.updateContentInsets()
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

        self.puzzleView = PuzzleView(puzzle: self.puzzle)
        self.puzzleView.solution = self.gameClient.solution
        self.puzzleView.isSolved = self.gameClient.isPuzzleSolved
        self.puzzleView.translatesAutoresizingMaskIntoConstraints = false
        self.puzzleView.delegate = self
        
        self.keyboardToolbar = PuzzleToolbarView()
        self.keyboardToolbar.translatesAutoresizingMaskIntoConstraints = false
        self.keyboardToolbar.delegate = self
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
            self.sideBarTapToDismissView.bottomAnchor.constraint(equalTo: self.keyboardToolbar.topAnchor),
            self.newMessageStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.67),
            self.newMessageStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.newMessageStackView.bottomAnchor.constraint(equalTo: self.keyboardToolbar.topAnchor, constant: -8)
        ])
                
        self.interactable = false
        
        if let gameId = self.puzzleIdToGameIdMap[self.puzzleId], gameId != "" {
            self.gameClient.connect(gameId: gameId)
            self.interactable = true
        } else {
            self.siteInteractor.createGame(puzzleId: self.puzzleId) { gameId in
                guard let gameId else {
                    let alert = UIAlertController(title: "Couldn't create game", message: "We couldn't create the game on DownForACross. Try again later.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                    return
                }
                self.puzzleIdToGameIdMap[self.puzzleId] = gameId
                self.gameClient.connect(gameId: gameId)
                self.interactable = true
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.puzzleView.becomeFirstResponder()
    }
    
    func updateContentInsets() {
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
        var baseURLComponents = Config.siteBaseURLComponents
        baseURLComponents.path = "/beta/game/\(self.gameClient.gameId)"
        UIPasteboard.general.url = baseURLComponents.url!
    }
    
    @objc func toggleSidebar() {
        if self.isSidebarVisible {
            self.puzzleView.becomeFirstResponder()
            self.keyboardToolbar.mode = .clues
            self.sideBarLeadingConstraint.constant = 0
            self.sideBarTapToDismissView.isUserInteractionEnabled = false
        } else {
            self.sideBarLeadingConstraint.constant = -self.sideBarViewController.view.frame.size.width
            self.sideBarTapToDismissView.isUserInteractionEnabled = true
            if self.sideBarViewController.currentTab == .messages {
                self.keyboardToolbar.mode = .messages
            }
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
        self.sideBarViewController.messagesViewController.addMessage(
            MessageAndPlayer(message: message, player: from))
        
        guard !(gameClient.isPerformingBulkEventSync || self.isSidebarVisible) else { return }
        
        self.newMessageStackView.addChatMessage(message, from: from)

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.view.layoutIfNeeded()
        }
    }
    
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]], isBulkUpdate: Bool, isSolved: Bool) {
        self.puzzleView.solution = solution
        
        if isSolved && !self.puzzleView.isSolved {
            self.playConfettiAnimation()
        }
        
        self.puzzleView.isSolved = isSolved
        
        if isBulkUpdate {
            self.puzzleView.advanceToAppropriateCellIfNecessary(
                isCurrentWordFullAndPotentiallyCorrect: self.puzzleView.currentWordIsFullAndPotentiallyCorrect())
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
    
    func puzzleView(_ puzzleView: PuzzleView, referencesInClueAtClueIndex clueIndex: Int, direction: Direction) -> [PuzzleClues.ClueReference] {
        var clue: String?
        switch direction {
            case .across:
                clue = self.puzzle.clues.across[clueIndex]
            case .down:
                clue = self.puzzle.clues.down[clueIndex]
        }
        
        guard let clue else { return [] }
        
        return PuzzleClues.findReferences(clue: clue)
    }
    
}


extension PuzzleViewController: PuzzleClueListViewControllerDelegate {
    
    func clueListViewController(_ clueListViewController: PuzzleClueListViewController, didSelectClueAtSequenceIndex sequenceIndex: Int, direction: Direction) {
        self.puzzleView.moveUserCursorToWord(atSequenceIndex: sequenceIndex, direction: direction)
    }
    
}

extension PuzzleViewController: PuzzleSideBarViewControllerDelegate {
    
    func sideBarViewController(_ sideBarViewController: PuzzleSideBarViewController, didSwitchToTab tab: PuzzleSideBarViewController.Tab) {
        switch tab {
            case .clues:
                self.keyboardToolbar.mode = .clues
                self.puzzleView.becomeFirstResponder()
            case .messages:
                self.keyboardToolbar.mode = .messages
        }
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

extension PuzzleViewController: PuzzleToolbarViewDelegate {
    
    func toolbarView(_ toolbarView: PuzzleToolbarView, didSendMessage message: String) {
        let sentEvent = self.gameClient.sendMessage(message)
        
        // player object doesn't matter because it's not used for messages sent by the user, only for messages
        // sent by others
        let messageAndPlayer = MessageAndPlayer(message: sentEvent,
                                                player: Player(displayName: "", color: .black))
        self.sideBarViewController.messagesViewController.addMessage(messageAndPlayer)
    }
    
}
