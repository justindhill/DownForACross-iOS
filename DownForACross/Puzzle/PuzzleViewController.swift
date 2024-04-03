//
//  PuzzleViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit
import WebKit
import Lottie
import Combine

class PuzzleViewController: UIViewController {
    
    static let puzzleIdToGameIdMapUserDefaultsKey = "com.justinhill.DownForACross.puzzleIdToGameIdMap"
    
    var viewHasAppeared: Bool = false
    let puzzleId: String
    let puzzle: Puzzle
    var gameId: String?
    let userId: String
    let siteInteractor: SiteInteractor
    let settingsStorage: SettingsStorage
    let api: API
    var puzzleIdToGameIdMap: [String: String] {
        didSet {
            UserDefaults.standard.setValue(puzzleIdToGameIdMap, forKey: Self.puzzleIdToGameIdMapUserDefaultsKey)
        }
    }
    
    var puzzleView: PuzzleView!
    var keyboardToolbar: PuzzleToolbarView!
    var keyboardToolbarBottomConstraint: NSLayoutConstraint!
    var titleBarAnimator: PuzzleTitleBarAnimator?
    var previewImageView: UIImageView = UIImageView()
    
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
     
    lazy var sideBarViewController: PuzzleSideBarViewController = {
        return PuzzleSideBarViewController(puzzle: self.puzzle, gameClient: self.gameClient, settingsStorage: self.settingsStorage)
    }()
    
    var sideBarTapToDismissView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    var sideBarLeadingConstraint: NSLayoutConstraint!
    lazy var sideBarTapToDismissGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleSidebar))
        return tap
    }()
    
    lazy var inputModeToggleTapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleInputMode))
        tap.numberOfTouchesRequired = 3
        return tap
    }()
    
    var newMessageStackView: PuzzleNewMessageStackView = PuzzleNewMessageStackView()
    var confettiView: LottieAnimationView?
    
    var gameClient: GameClient {
        didSet {
            oldValue.delegate = nil
            gameClient.delegate = self
            self.sideBarViewController.gameClient = gameClient
        }
    }

    var isSidebarVisible: Bool {
        return self.sideBarLeadingConstraint.constant < 0
    }

    var subscriptions: [AnyCancellable] = []

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // assumes that GameClient is connected and has done a bulk sync to get all of the necessary info from the create event
    init(gameClient: GameClient, siteInteractor: SiteInteractor, api: API, settingsStorage: SettingsStorage) {
        self.gameClient = gameClient
        self.puzzle = gameClient.puzzle
        self.puzzleId = gameClient.puzzleId
        self.gameId = gameClient.gameId
        self.userId = gameClient.userId
        self.api = api
        self.siteInteractor = siteInteractor
        self.settingsStorage = settingsStorage

        if let gameIdMap = UserDefaults.standard.object(forKey: Self.puzzleIdToGameIdMapUserDefaultsKey) as? [String: String] {
            self.puzzleIdToGameIdMap = gameIdMap
        } else {
            self.puzzleIdToGameIdMap = [:]
        }

        super.init(nibName: nil, bundle: nil)

        self.gameClient.delegate = self
        self.sideBarViewController.messagesViewController.selfUserId = userId
        self.hidesBottomBarWhenPushed = true
    }

    init(puzzle: Puzzle, puzzleId: String, userId: String, gameId: String? = nil, siteInteractor: SiteInteractor, api: API, settingsStorage: SettingsStorage) {
        self.puzzle = puzzle
        self.puzzleId = puzzleId
        self.userId = userId
        self.siteInteractor = siteInteractor
        self.settingsStorage = settingsStorage
        self.api = api
        
        if let gameIdMap = UserDefaults.standard.object(forKey: Self.puzzleIdToGameIdMapUserDefaultsKey) as? [String: String] {
            self.puzzleIdToGameIdMap = gameIdMap
        } else {
            self.puzzleIdToGameIdMap = [:]
        }
        
        let resolvedGameId = gameId ?? self.puzzleIdToGameIdMap[puzzleId] ?? ""
        self.gameId = resolvedGameId
        self.gameClient = GameClient(puzzle: self.puzzle, puzzleId: self.puzzleId, userId: self.userId, gameId: resolvedGameId, settingsStorage: self.settingsStorage)

        super.init(nibName: nil, bundle: nil)

        self.gameClient.delegate = self
        self.sideBarViewController.messagesViewController.selfUserId = userId
        self.hidesBottomBarWhenPushed = true
    }
    
    lazy var contextMenuInteraction = UIContextMenuInteraction(delegate: self)
    
    override func viewDidLoad() {
        self.sideBarViewController.delegate = self
        self.sideBarViewController.playersViewController.delegate = self
        self.sideBarTapToDismissView.addGestureRecognizer(self.sideBarTapToDismissGestureRecognizer)

        self.sideBarViewController.clueListViewController.delegate = self

        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIControl.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIControl.keyboardWillHideNotification,
                                               object: nil)

        self.subscriptions.append(self.sideBarViewController.messagesViewController.$hasUnreadMessages
            .didSet
            .sink { [weak self] _ in
            self?.updateMenuContents()
        })

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.contextualmenu)
        self.navigationItem.largeTitleDisplayMode = .never

        self.view.backgroundColor = .systemBackground
        self.view.addGestureRecognizer(self.swipeGestureRecognizer)

        self.puzzleView = PuzzleView(puzzle: self.puzzle)
        self.puzzleView.solution = self.gameClient.solution
        self.puzzleView.isSolved = self.gameClient.isPuzzleSolved
        self.puzzleView.skipFilledCells = self.settingsStorage.skipFilledCells
        self.puzzleView.translatesAutoresizingMaskIntoConstraints = false
        self.puzzleView.delegate = self
        self.puzzleView.addGestureRecognizer(self.inputModeToggleTapGestureRecognizer)
        self.puzzleView.addInteraction(self.contextMenuInteraction)
        
        self.keyboardToolbar = PuzzleToolbarView()
        self.keyboardToolbar.translatesAutoresizingMaskIntoConstraints = false
        self.keyboardToolbar.delegate = self
        self.puzzleView(self.puzzleView, userCursorDidMoveToClue: PuzzleView.ModelLocation(clueIndex: 1,
                                                                                           sequenceIndex: 0,
                                                                                           direction: self.puzzleView.userCursor.direction))
        
        
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
        
        self.previewImageView.isHidden = true
        self.previewImageView.isUserInteractionEnabled = false
        self.view.addSubview(self.previewImageView)

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
            self.sideBarTapToDismissView.trailingAnchor.constraint(equalTo: self.sideBarViewController.view.leadingAnchor),
            self.sideBarTapToDismissView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.sideBarTapToDismissView.bottomAnchor.constraint(equalTo: self.keyboardToolbar.topAnchor),
            self.newMessageStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.67),
            self.newMessageStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.newMessageStackView.bottomAnchor.constraint(equalTo: self.keyboardToolbar.topAnchor, constant: -8)
        ])
                
        self.updateMenuContents()
        self.interactable = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.puzzleView.userCursorColor = self.settingsStorage.userDisplayColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            self.titleBarAnimator = PuzzleTitleBarAnimator(navigationBar: navigationBar, navigationItem: self.navigationItem)
        }
        
        if self.gameClient.defersJoining {
            self.gameClient.joinGame()
        }

        if self.gameClient.connectionState == .connected {
            self.gameClient(self.gameClient, connectionStateDidChange: .connected)
            return
        }

        if let gameId = self.gameId, gameId != "" {
            self.gameClient.connect()
        } else {
            self.titleBarAnimator?.showPill(withText: "Creating game", timeout: nil, icon: .spinner, animated: false)
            self.siteInteractor.createGame(puzzleId: self.puzzleId) { [weak self] gameId in
                guard let self else { return }
                guard let gameId else {
                    let alert = UIAlertController(title: "Couldn't create game", message: "We couldn't create the game on DownForACross. Try again later.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                    return
                }
                self.gameId = gameId
                self.puzzleIdToGameIdMap[self.puzzleId] = gameId
                self.gameClient = GameClient(puzzle: self.puzzle, puzzleId: self.puzzleId, userId: self.userId, gameId: gameId, settingsStorage: self.settingsStorage)
                self.gameClient.connect()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.puzzleView.becomeFirstResponder()
        self.titleBarAnimator?._titleControl = nil

        if !viewHasAppeared {
            self.viewHasAppeared = true
            DispatchQueue.main.async {
                self.sideBarViewController.beginAppearanceTransition(false, animated: false)
                self.sideBarViewController.endAppearanceTransition()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateContentInsets()
    }

    @objc func keyboardWillShow(_ note: Notification) {
        guard let userInfo = note.userInfo else { return }
        let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        self.currentKeyboardHeight = keyboardSize.height
        self.updateContentInsets()
    }

    @objc func keyboardWillHide(_ note: Notification) {
        self.currentKeyboardHeight = 0
        self.updateContentInsets()
    }

    func updateContentInsets() {
        if !self.previewImageView.isHidden {
            // the keyboard gets hidden when a context menu is open, which can cause content offset to shift when adjusting insets
            return
        }
        
        self.puzzleView.scrollView.contentInset.bottom =
            self.keyboardToolbar.frame.size.height + self.currentKeyboardHeight - self.view.safeAreaInsets.bottom
        
        if self.currentKeyboardHeight == 0 {
            self.keyboardToolbarBottomConstraint.constant = self.view.safeAreaInsets.bottom
        } else {
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
    
    @objc func toggleSidebar() {
        if self.isSidebarVisible {
            self.sideBarViewController.beginAppearanceTransition(false, animated: true)
            self.puzzleView.becomeFirstResponder()
            self.keyboardToolbar.mode = .clues
            self.sideBarLeadingConstraint.constant = 0
            self.sideBarTapToDismissView.isUserInteractionEnabled = false
        } else {
            self.sideBarViewController.beginAppearanceTransition(true, animated: true)
            self.sideBarLeadingConstraint.constant = -self.sideBarViewController.view.frame.size.width
            self.sideBarTapToDismissView.isUserInteractionEnabled = true
            if self.sideBarViewController.currentTab == .messages {
                self.keyboardToolbar.mode = .messages
            }
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.sideBarTapToDismissView.backgroundColor = self.isSidebarVisible
                ? UIColor.black.withAlphaComponent(0.4)
                : UIColor.clear
            self.view.layoutIfNeeded()
        }) { _ in
            self.sideBarViewController.endAppearanceTransition()
        }
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
    
    @objc func toggleInputMode() {
        let newIndex = (self.gameClient.inputMode.rawValue + 1) % GameClient.InputMode.allCases.count
        guard let newInputMode = GameClient.InputMode(rawValue: newIndex) else { return }
        self.gameClient.inputMode = newInputMode
        self.titleBarAnimator?.showPill(withText: newInputMode.displayString, icon: .pencil)

        if newInputMode == .pencil {
            self.newMessageStackView.addSystemMessage("Pencil mode isn't implemented yet!")
        }
    }

    func updateMenuContents() {
        var messagesIcon: UIImage?
        var newBarItemIcon: UIImage?
        if self.sideBarViewController.messagesViewController.hasUnreadMessages {
            messagesIcon = PuzzleSideBarViewController.Tab.messages.badgedImage
            newBarItemIcon = UIImage.contextualmenuBadge
                                    .applyingSymbolConfiguration(.init(paletteColors: [.systemRed, .systemBlue]))
        } else {
            messagesIcon = PuzzleSideBarViewController.Tab.messages.image
            newBarItemIcon = UIImage.contextualmenu
                                    .applyingSymbolConfiguration(.init(paletteColors: [.systemRed, .systemBlue]))
        }

        if let newBarItemIcon {
            self.navigationItem.rightBarButtonItem?.setSymbolImage(newBarItemIcon, contentTransition: .replace.byLayer)
        }

        var menuElements: [UIMenuElement] = [
            UIAction(title: "Clues", image: PuzzleSideBarViewController.Tab.clues.image, handler: { [weak self] _ in
                guard let self else { return }
                self.sideBarViewController.setCurrentTab(.clues, animated: self.isSidebarVisible)
                if !self.isSidebarVisible {
                    self.toggleSidebar()
                }
            }),
            UIAction(title: "Players", image: PuzzleSideBarViewController.Tab.players.image, handler: { [weak self] _ in
                guard let self else { return }
                self.sideBarViewController.setCurrentTab(.players, animated: self.isSidebarVisible)
                if !self.isSidebarVisible {
                    self.toggleSidebar()
                }
            }),
            UIAction(title: "Messages", image: messagesIcon, handler: { [weak self] _ in
                guard let self else { return }
                self.sideBarViewController.setCurrentTab(.messages, animated: self.isSidebarVisible)
                if !self.isSidebarVisible {
                    self.toggleSidebar()
                }
            }),
            UIAction(title: "Color attribution",
                     image: self.puzzleView.isPlayerAttributionEnabled 
                        ? UIImage(systemName: "checkmark.square")
                        : UIImage(systemName: "square"),
                     handler: { [weak self] _ in
                guard let self else { return }
                self.puzzleView.isPlayerAttributionEnabled = !self.puzzleView.isPlayerAttributionEnabled
                self.updateMenuContents()
            }),
            UIMenu(title: "Input mode", image: UIImage(systemName: "pencil"), children: GameClient.InputMode.allCases.map({ inputMode in
                let isCurrent = inputMode == self.gameClient.inputMode
                return UIAction(title: inputMode.displayString,
                         image: isCurrent ? UIImage(systemName: "checkmark") : nil,
                         handler: { [weak self] _ in
                    guard let self else { return }
                    self.gameClient.inputMode = inputMode
                    self.updateMenuContents()

                    if inputMode == .pencil {
                        self.newMessageStackView.addSystemMessage("Pencil mode isn't implemented yet.")
                    } else {
                        self.showInputModeQuickswitchTooltipIfNecessary()
                    }
                })
            }))
        ]

        menuElements.append(contentsOf: self.checkRevealResetMenus(includingFullPuzzleOption: true))

        menuElements.append(UIAction(title: "Invite others", image: UIImage(systemName: "square.and.arrow.up"), handler: { [weak self] action in
            guard let self, let sender = action.sender as? UIBarButtonItem else { return }
            self.presentShareSheet(fromView: nil, orBarButtonItem: sender)
        }))

        self.navigationItem.rightBarButtonItem?.menu = UIMenu(children: menuElements)
    }

    func presentShareSheet(fromView view: UIView?, orBarButtonItem item: UIBarButtonItem?) {
        if view == nil && item == nil {
            assertionFailure("View or item must be populated!")
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "dfac.link"
        components.path = "/beta/game/\(self.gameClient.gameId)"

        #if targetEnvironment(simulator)
        let url = components.url!.absoluteString
        #else
        let url = components.url!
        #endif

        let text = "Join my crossword on DownForACross!"

        let activityViewController = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.popoverPresentationController?.sourceItem = item
        self.present(activityViewController, animated: true)
    }

    func checkRevealResetMenus(includingFullPuzzleOption puzzle: Bool) -> [UIMenu] {
        var checkMenuActions: [UIAction] = [
            UIAction(title: "Square", handler: { [weak self] _ in
                guard let self else { return }
                self.gameClient.check(cells: [self.puzzleView.userCursor.coordinates])
            }),
            UIAction(title: "Word", handler: { [weak self] _ in
                guard let self else { return }
                self.gameClient.check(cells: self.puzzleView.findCurrentWordCellCoordinates())
            })
        ]

        if puzzle {
            checkMenuActions.append(UIAction(title: "Puzzle", handler: { [weak self] _ in
                guard let self else { return }
                self.gameClient.check(cells: self.puzzleView.findAllLetterCellCoordinates())
            }))
        }

        var revealMenuActions: [UIAction] = [
            UIAction(title: "Square", handler: { [weak self] _ in
                guard let self else { return }
                self.showConfirmationAlert(title: "Reveal the square?",
                                           message: "The correct letter will be filled in for all players.",
                                           confirmActionTitle: "Reveal") { [weak self] in
                    guard let self else { return }
                    self.gameClient.reveal(cells: [self.puzzleView.userCursor.coordinates])
                }
            }),
            UIAction(title: "Word", handler: { [weak self] _ in
                guard let self else { return }
                self.showConfirmationAlert(title: "Reveal the word?",
                                           message: "The correct letters will be filled in for all players.",
                                           confirmActionTitle: "Reveal") { [weak self] in
                    guard let self else { return }
                    self.gameClient.reveal(cells: self.puzzleView.findCurrentWordCellCoordinates())
                }
            })
        ]

        if puzzle {
            revealMenuActions.append(UIAction(title: "Puzzle", handler: { [weak self] _ in
                guard let self else { return }
                self.showConfirmationAlert(title: "Reveal the whole puzzle?", 
                                           message: "The correct letters will be filled in for all players.",
                                           confirmActionTitle: "Reveal") { [weak self] in
                    guard let self else { return }
                    self.gameClient.reveal(cells: self.puzzleView.findAllLetterCellCoordinates())
                }
            }))
        }

        var resetMenuActions: [UIAction] = [
            UIAction(title: "Square", handler: { [weak self] _ in
                guard let self else { return }
                self.gameClient.reset(cells: [self.puzzleView.userCursor.coordinates])
            }),
            UIAction(title: "Word", handler: { [weak self] _ in
                guard let self else { return }
                self.gameClient.reset(cells: self.puzzleView.findCurrentWordCellCoordinates())
            })
        ]

        if puzzle {
            resetMenuActions.append(UIAction(title: "Puzzle", handler: { [weak self] _ in
                guard let self else { return }
                self.showConfirmationAlert(title: "Reset the whole puzzle?",
                                           message: "The entire puzzle will be cleared out for all players.",
                                           confirmActionTitle: "Reset") { [weak self] in
                    guard let self else { return }
                    self.gameClient.reset(cells: self.puzzleView.findAllLetterCellCoordinates())
                }
            }))
        }

        let checkMenu = UIMenu(title: "Check", identifier: nil, options: [], preferredElementSize: .automatic, children: checkMenuActions)
        let revealMenu = UIMenu(title: "Reveal", identifier: nil, options: [], preferredElementSize: .automatic, children: revealMenuActions)
        let resetMenu = UIMenu(title: "Reset", identifier: nil, options: [], preferredElementSize: .automatic, children: resetMenuActions)

        return [checkMenu, revealMenu, resetMenu]
    }

    func showInputModeQuickswitchTooltipIfNecessary() {
        if !self.settingsStorage.hasSeenInputModeQuickswitchTooltip {
            self.newMessageStackView.addSystemMessage("Tap the puzzle with three fingers to quickly switch between input modes!")
            self.settingsStorage.hasSeenInputModeQuickswitchTooltip = true
        }
    }

    func showConfirmationAlert(title: String, message: String, confirmActionTitle: String, confirmBlock: @escaping (() -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Reveal", style: .destructive, handler: { _ in
            confirmBlock()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        self.present(alert, animated: true)
    }
}

extension PuzzleViewController: GameClientDelegate {

    func gameClient(_ client: GameClient, newPlayerJoined player: Player) {
        print("Player joined: \(player.displayName)")
        self.titleBarAnimator?.showPill(withText: "\(player.displayName) joined", icon: .circle(color: player.color))
    }
    
    func gameClient(_ client: GameClient, didReceiveNewChatMessage message: ChatEvent, from: Player) {
        self.sideBarViewController.messagesViewController.addMessage(
            MessageAndPlayer(message: message, playerId: from.userId))

        guard !(gameClient.isPerformingBulkEventSync || self.isSidebarVisible) else { return }
        
        if self.settingsStorage.showMessagePreviews {
            self.newMessageStackView.addChatMessage(message, from: from)
        }
        
        self.updateMenuContents()
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
    
    func gameClient(_ client: GameClient, connectionStateDidChange connectionState: GameClient.ConnectionState) {
        switch connectionState {
            case .disconnected:
                self.interactable = false
            case .connecting, .syncing:
                self.interactable = false
                self.titleBarAnimator?.showPill(withText: connectionState.displayString, timeout: nil, icon: .spinner, animated: self.viewHasAppeared)
            case .connected:
                self.interactable = true
                self.titleBarAnimator?.showPill(withText: connectionState.displayString, icon: .success, animated: self.viewHasAppeared)
                break
        }
    }
    
}

extension PuzzleViewController: PuzzleViewDelegate {
    
    func puzzleView(_ puzzleView: PuzzleView, userCursorDidMoveToClue clue: PuzzleView.ModelLocation?) {
        guard let clue else {
            self.sideBarViewController.clueListViewController.selectClue(atSequenceIndex: nil, direction: .across)
            self.keyboardToolbar.clueLabel.text = ""
            return
        }
        
        switch clue.direction {
            case .across:
                self.keyboardToolbar.clueLabel.text = self.puzzle.clues.across[clue.clueIndex]
            case .down:
                self.keyboardToolbar.clueLabel.text = self.puzzle.clues.down[clue.clueIndex]
        }
        
        self.sideBarViewController.clueListViewController.selectClue(atSequenceIndex: clue.sequenceIndex, direction: clue.direction)
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
            case .clues, .players:
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
        let messageAndPlayer = MessageAndPlayer(message: sentEvent,
                                                playerId: self.gameClient.userId)
        self.sideBarViewController.messagesViewController.addMessage(messageAndPlayer)
    }
    
}

extension PuzzleViewController: PuzzlePlayersViewControllerDelegate {
    
    func playersViewControllerDidSelectSendInvite(_ playersViewController: PuzzlePlayersViewController, sourceView: UIView) {
        self.presentShareSheet(fromView: sourceView, orBarButtonItem: nil)
    }
    
}

extension PuzzleViewController: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            guard let self else { return nil }
            return UIMenu(title: "",
                   image: nil,
                   identifier: .root,
                   options: [.displayInline],
                   children: self.checkRevealResetMenus(includingFullPuzzleOption: false)
            )
        })
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: any NSCopying) -> UITargetedPreview? {
        DispatchQueue.main.async {
            self.previewImageView.isHidden = false
        }
        let sideLength = self.puzzleView.cellSideLength
        let scaledSideLength = sideLength * self.puzzleView.scrollView.zoomScale
        var rect = self.puzzleView.boundingBoxOfCurrentWord(cellSideLength: sideLength)
        rect = rect.offsetBy(dx: self.puzzleView.puzzleContainerView.frame.origin.x,
                      dy: self.puzzleView.puzzleContainerView.frame.origin.y)
        rect = rect.scaled(by: self.puzzleView.scrollView.zoomScale)
        rect = rect.insetBy(dx: -scaledSideLength * 0.3, dy: -scaledSideLength * 0.3)
        let parentOrigin = self.puzzleView.scrollView.convert(rect.origin, to: self.view)
        let parentRect = CGRect(origin: parentOrigin, size: rect.size)
        self.previewImageView.frame = parentRect
        self.previewImageView.image = self.puzzleView.scrollView.snapshot(of: rect)
        return UITargetedPreview(view: self.previewImageView)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        let sideLength = self.puzzleView.cellSideLength
        let scaledSideLength = sideLength * self.puzzleView.scrollView.zoomScale
        var rect = self.puzzleView.boundingBoxOfCurrentWord(cellSideLength: sideLength)
        rect = rect.offsetBy(dx: self.puzzleView.puzzleContainerView.frame.origin.x,
                      dy: self.puzzleView.puzzleContainerView.frame.origin.y)
        rect = rect.scaled(by: self.puzzleView.scrollView.zoomScale)
        rect = rect.insetBy(dx: -scaledSideLength * 0.3, dy: -scaledSideLength * 0.3)
        self.puzzleView.layoutIfNeeded()
        
        let image = self.puzzleView.scrollView.snapshot(of: rect, afterScreenUpdates: true)
        self.previewImageView.image = image
        
        animator?.addCompletion {
            self.previewImageView.isHidden = true
            self.updateContentInsets()
        }
    }
    
}
