//
//  ViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit
import WebKit
import Combine
import Reachability

class PuzzleListViewController: UIViewController, UITableViewDelegate, UITableViewDataSourcePrefetching {
    
    enum Section: Int {
        case puzzles
        case loadMore
    }
    
    enum RefreshType {
        case pullToRefresh
        case loadMore
        case offline
        case other
    }
    
    let listItemReuseIdentifier: String = "ItemReuseIdentifier"
    let loadingSpinnerReuseIdentifier: String = "LoadingSpinnerReuseIdentifier"
    let reachedEndReuseIdentifier: String = "ReachedEndReuseIdentifier"

    var isOffline: Bool = false {
        didSet {
            self.offlineBar.isHidden = !isOffline
            self.quickFilterBar.isHidden = isOffline
        }
    }

    let emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var offlineBar: UIView = {
        let label = UILabel()
        label.text = "You're in offline mode."

        let goOnlineButton = UIButton(configuration: .plain())
        goOnlineButton.configuration?.title = "Go online"
        goOnlineButton.configuration?.contentInsets = .zero
        goOnlineButton.addAction(UIAction { [weak self] _ in
            self?.goOnlineButtonTapped()
        }, for: .primaryActionTriggered)

        let stackView = UIStackView(arrangedSubviews: [label, goOnlineButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.preservesSuperviewLayoutMargins = true

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stackView)
        container.backgroundColor = UIColor.offlineBarBackground
        container.preservesSuperviewLayoutMargins = true

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor)
        ])

        return container
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.refreshControl = self.refreshControl
        return tableView
    }()
    
    lazy var dataSource: UITableViewDiffableDataSource = {
        UITableViewDiffableDataSource<Int, PuzzleListEntry>(tableView: self.tableView) { [weak self] tableView, indexPath, puzzle in
            guard let self, let section = Section(rawValue: indexPath.section) else { fatalError() }
            switch section {
                case .puzzles:
                    let cell = tableView.dequeueReusableCell(withIdentifier: self.listItemReuseIdentifier, for: indexPath)
                    var config = cell.defaultContentConfiguration()
                    config.text = puzzle.content.info.title
                    config.secondaryText = puzzle.content.info.author
                    config.secondaryTextProperties.color = .secondaryLabel
                    cell.contentConfiguration = config

                    if let gameId = self.settingsStorage.puzzleIdToGameIdMap[puzzle.pid],
                       let completion = self.settingsStorage.gameIdToCompletion[gameId] {
                        cell.accessoryView = completion.createAccessoryImageView()
                    } else {
                        cell.accessoryView = nil
                    }

                    return cell
                case .loadMore:
                    if self.hasReachedLastPage {
                        let cell = tableView.dequeueReusableCell(withIdentifier: self.reachedEndReuseIdentifier, for: indexPath)
                        let labelTag = 999
                        
                        if cell.contentView.viewWithTag(labelTag) == nil {
                            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
                            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
                            
                            let label = UILabel()
                            label.translatesAutoresizingMaskIntoConstraints = false
                            label.tag = labelTag
                            label.font = UIFont.preferredFont(forTextStyle: .body)
                            label.textColor = UIColor.secondaryLabel
                            label.text = "Nothing to see! You reached the end."
                            
                            cell.contentView.addSubview(label)
                            NSLayoutConstraint.activate([
                                label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                            ])
                        }
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: self.loadingSpinnerReuseIdentifier, for: indexPath)

                        let spinnerTag = 1000
                        if let spinner = cell.contentView.viewWithTag(spinnerTag) as? UIActivityIndicatorView {
                            spinner.startAnimating()
                        } else {
                            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
                            cell.contentView.layoutMargins = UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
                            
                            let spinner = UIActivityIndicatorView(style: .medium)
                            spinner.tag = spinnerTag
                            spinner.translatesAutoresizingMaskIntoConstraints = false
                            cell.contentView.addSubview(spinner)
                            NSLayoutConstraint.activate([
                                spinner.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                                spinner.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                            ])
                            spinner.startAnimating()
                        }
                        
                        if self.updateTask == nil {
                            self.updatePuzzleList(refreshType: .loadMore)
                        }
                        
                        return cell
                    }
            }
        }
    }()
    
    lazy var quickFilterBar: PuzzleListQuickFilterBarView = {
        let view = PuzzleListQuickFilterBarView(settingsStorage: self.settingsStorage)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    var updateTask: AnyCancellable?
    
    let pageLimit: Int = 50
    var hasReachedLastPage: Bool = false
    var page: Int = 0
    
    var userId: String
    let siteInteractor: SiteInteractor
    let api: API
    let settingsStorage: SettingsStorage
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlDidBeginRefreshing), for: .primaryActionTriggered)
        return refreshControl
    }()
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(userId: String, settingsStorage: SettingsStorage, api: API, siteInteractor: SiteInteractor) {
        self.userId = userId
        self.settingsStorage = settingsStorage
        self.api = api
        self.siteInteractor = siteInteractor
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Down For a Cross"
        self.navigationItem.backButtonTitle = ""
        self.tableView.dataSource = self.dataSource
        self.tableView.prefetchDataSource = self
        
        self.view.backgroundColor = .systemBackground
        self.tableView.backgroundColor = .clear
                
        self.view.addSubview(self.emptyStateView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.quickFilterBar)
        self.view.addSubview(self.offlineBar)

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.listItemReuseIdentifier)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.loadingSpinnerReuseIdentifier)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.reachedEndReuseIdentifier)
        
        NSLayoutConstraint.activate([
            self.emptyStateView.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.emptyStateView.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            self.emptyStateView.label.centerYAnchor.constraint(equalTo: self.view.layoutMarginsGuide.centerYAnchor),
            self.quickFilterBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.quickFilterBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.quickFilterBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.offlineBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.offlineBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.offlineBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.offlineBar.bottomAnchor.constraint(equalTo: self.quickFilterBar.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.quickFilterBar.bottomAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

//        let r = try! Reachability()
        self.isOffline = true //(r.connection != .unavailable)

        let refreshType: RefreshType = self.isOffline ? .offline : .other
        self.updatePuzzleList(refreshType: refreshType)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
            var snapshot = self.dataSource.snapshot()
            let ids = visibleIndexPaths.compactMap({ self.dataSource.itemIdentifier(for: $0) })
            snapshot.reloadItems(ids)

            self.dataSource.apply(snapshot)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let puzzleListEntry = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.show(puzzleListEntry: puzzleListEntry, 
                  gameId: self.settingsStorage.puzzleIdToGameIdMap[puzzleListEntry.pid])
    }
    
    func show(puzzleListEntry: PuzzleListEntry, gameId: String? = nil) {
        if self.isOffline {
            let vc = PuzzleViewController(gameClient: OfflineGameClient(puzzle: puzzleListEntry.content,
                                                                        puzzleId: puzzleListEntry.pid,
                                                                        userId: self.userId,
                                                                        settingsStorage: self.settingsStorage),
                                          siteInteractor: OfflineSiteInteractor(),
                                          api: self.api,
                                          settingsStorage: self.settingsStorage)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = PuzzleViewController(puzzle: puzzleListEntry.content,
                                          puzzleId: puzzleListEntry.pid,
                                          userId: self.userId,
                                          gameId: gameId,
                                          siteInteractor: self.siteInteractor,
                                          api: self.api,
                                          settingsStorage: self.settingsStorage)

            if let gameId {
                self.settingsStorage.gameIdToCompletion[gameId] = vc.gameClient.solutionState
            }

            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func updatePuzzleList(refreshType: RefreshType) {
        self.updateTask = AnyCancellable(Task {
            do {
                switch refreshType {
                    case .pullToRefresh:
                        self.page = 0
                        self.refreshControl.beginRefreshing()
                    case .other:
                        self.page = 0
                        if self.dataSource.numberOfSections(in: self.tableView) > 0 && self.dataSource.tableView(self.tableView, numberOfRowsInSection: 0) > 0 {
                            self.addPulsingAnimation(on: self.tableView)
                        } else {
                            self.emptyStateView.activityIndicator.isHidden = false
                            self.emptyStateView.activityIndicator.startAnimating()
                        }
                    case .loadMore:
                        self.page += 1
                        break
                    case .offline:
                        self.page = 0
                }

                if refreshType == .offline {
                    let puzzleList = await self.loadOfflinePuzzles()
                    self.hasReachedLastPage = true

                    var snapshot = NSDiffableDataSourceSnapshot<Int, PuzzleListEntry>()
                    snapshot.appendSections([0])
                    snapshot.appendItems(puzzleList)
                    await self.dataSource.apply(snapshot, animatingDifferences: false)
                } else {
                    let puzzleList = try await api.getPuzzleList(
                        page: self.page,
                        wordFilter: self.quickFilterBar.selectedWordFilter,
                        includeMinis: self.quickFilterBar.selectedPuzzleSize.includeMinis,
                        includeStandards: self.quickFilterBar.selectedPuzzleSize.includeStandards,
                        limit: self.pageLimit)

                    self.hasReachedLastPage = puzzleList.puzzles.count < self.pageLimit

                    var snapshot: NSDiffableDataSourceSnapshot<Int, PuzzleListEntry>
                    if refreshType == .loadMore {
                        snapshot = self.dataSource.snapshot()
                        snapshot.appendItems(puzzleList.puzzles, toSection: Section.puzzles.rawValue)

                        if self.hasReachedLastPage {
                            snapshot.reloadSections([Section.loadMore.rawValue])
                        }
                    } else {
                        snapshot = NSDiffableDataSourceSnapshot<Int, PuzzleListEntry>()
                        snapshot.appendSections([Section.puzzles.rawValue])
                        snapshot.appendItems(puzzleList.puzzles, toSection: Section.puzzles.rawValue)

                        if puzzleList.puzzles.count == self.pageLimit {
                            snapshot.appendSections([Section.loadMore.rawValue])
                            snapshot.appendItems([PuzzleListEntry(pid: "LOADMORE", content: Puzzle.empty(), stats: PuzzleStats(numSolves: 0))])
                        }
                    }
                    await self.dataSource.apply(snapshot, animatingDifferences: false)

                    self.removePulsingAnimation(from: self.tableView)
                    self.emptyStateView.activityIndicator.stopAnimating()
                    self.emptyStateView.activityIndicator.isHidden = true
                    self.refreshControl.endRefreshing()

                    if refreshType == .other {
                        tableView.contentOffset = .zero
                    }

                    if puzzleList.puzzles.count == 0 {
                        self.emptyStateView.label.text = "No puzzles found"
                        self.emptyStateView.isHidden = false
                    } else {
                        self.emptyStateView.isHidden = true
                    }
                }
            } catch {
                self.emptyStateView.label.text = "Couldn't load the puzzle list"
                self.quickFilterBar.isUserInteractionEnabled = true
                self.emptyStateView.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                self.removePulsingAnimation(from: self.tableView)

                await self.clearPuzzleList()
                self.emptyStateView.isHidden = false
                print(error)
            }
        }.cancel)
    }

    func clearPuzzleList() async {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PuzzleListEntry>()
        snapshot.appendSections([Section.puzzles.rawValue])
        snapshot.appendItems([], toSection: Section.puzzles.rawValue)
        await self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    func goOnlineButtonTapped() {
        self.isOffline = false
        Task {
            await self.clearPuzzleList()
            self.updatePuzzleList(refreshType: .other)
        }
    }

    func addPulsingAnimation(on view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [1, 0.5, 1]
        animation.timingFunctions = [CAMediaTimingFunction(name: .easeIn), CAMediaTimingFunction(name: .easeOut)]
        animation.duration = 1
        animation.repeatCount = 10000

        view.layer.add(animation, forKey: "pulsing")
    }

    func removePulsingAnimation(from view: UIView) {
        view.layer.removeAnimation(forKey: "pulsing")
    }

    @objc func refreshControlDidBeginRefreshing() {
        let refreshType: RefreshType = self.isOffline ? .offline : .pullToRefresh
        self.updatePuzzleList(refreshType: refreshType)
    }

    func loadOfflinePuzzles() async -> [PuzzleListEntry] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: Self.savePath, isDirectory: &isDirectory),
                isDirectory.boolValue,
                let savedPuzzles = try? FileManager.default.contentsOfDirectory(atPath: Self.savePath) else {
            return []
        }

        let decoder = JSONDecoder()
        var puzzleEntries: [PuzzleListEntryOfflineSave] = []
        savedPuzzles.forEach { puzzleFile in
            let path = (Self.savePath as NSString).appendingPathComponent(puzzleFile)
            if let fileContents = FileManager.default.contents(atPath: path as String),
                let listEntry = try? decoder.decode(PuzzleListEntryOfflineSave.self, from: fileContents) {
                puzzleEntries.append(listEntry)
            }
        }

        puzzleEntries.sort(using: KeyPathComparator(\.saveDate))
        return puzzleEntries.map { $0.entry }
    }

    static var savePath: String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath: String = (documentsDirectory as NSString).appendingPathComponent("offlineSaves")
        return filePath
    }

    static func createSavePathIfNecessary() {
        var isDirectory: ObjCBool = false
        if !(FileManager.default.fileExists(atPath: self.savePath, isDirectory: &isDirectory) && isDirectory.boolValue) {
            var components = URLComponents(string: self.savePath)!
            components.scheme = "file"
            try? FileManager.default.createDirectory(at: components.url!, withIntermediateDirectories: true)
        }
    }

    static func createFilePath(forListEntry listEntry: PuzzleListEntry) -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        var filePath: String = (documentsDirectory as NSString).appendingPathComponent("offlineSaves")
        filePath = (filePath as NSString).appendingPathComponent("\(listEntry.pid).json")

        return filePath
    }

    static func isPuzzleSavedForOfflinePlay(puzzleListEntry: PuzzleListEntry) -> Bool {
        let path = self.createFilePath(forListEntry: puzzleListEntry)
        return FileManager.default.fileExists(atPath: path)
    }

    func savePuzzleForOfflinePlay(puzzleListEntry: PuzzleListEntry) {
        let filePath = Self.createFilePath(forListEntry: puzzleListEntry)
        let jsonEncoder = JSONEncoder()

        let saveState = PuzzleListEntryOfflineSave(entry: puzzleListEntry)

        guard let encodedSaveState = try? jsonEncoder.encode(saveState) else {
            print("Couldn't encode the solution")
            return
        }

        Self.createSavePathIfNecessary()

        let success = FileManager.default.createFile(atPath: filePath, contents: encodedSaveState, attributes: nil)
        if !success {
            print("Unable to write solution file for \(puzzleListEntry.pid)")
        }
    }

    func removePuzzleOfflineCopy(puzzleListEntry: PuzzleListEntry) {
        let filePath = Self.createFilePath(forListEntry: puzzleListEntry)
        try? FileManager.default.removeItem(atPath: filePath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { fatalError() }
        switch section {
            case .loadMore:
                return 75
            case .puzzles:
                return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let shouldLoadMore = indexPaths.reduce(false, { $0 || $1.section == Section.loadMore.rawValue })
        if shouldLoadMore {
            self.updatePuzzleList(refreshType: .loadMore)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let entry = self.dataSource.itemIdentifier(for: indexPath) else { return nil }

        if indexPath.section == Section.puzzles.rawValue {
            if Self.isPuzzleSavedForOfflinePlay(puzzleListEntry: entry) {
                return UISwipeActionsConfiguration(actions: [
                    UIContextualAction(style: .destructive, title: "Delete offline copy", handler: { _, _, completion in
                        self.removePuzzleOfflineCopy(puzzleListEntry: entry)

                        if self.isOffline {
                            var snapshot = self.dataSource.snapshot()
                            snapshot.deleteItems([entry])
                            self.dataSource.apply(snapshot)
                        }

                        completion(true)
                    })
                ])
            } else {
                return UISwipeActionsConfiguration(actions: [
                    UIContextualAction(style: .normal, title: "Make available offline", handler: { _, _, completion in
                        self.savePuzzleForOfflinePlay(puzzleListEntry: entry)
                        completion(true)
                    })
                ])
            }
        }

        return nil
    }

}

extension PuzzleListViewController: PuzzleListQuickFilterBarViewDelegate {
    
    func filterBar(_ filterBar: PuzzleListQuickFilterBarView, selectedSizesDidChange size: PuzzleListQuickFilterBarView.PuzzleSize) {
        self.settingsStorage.puzzleListSizeFilter = size
        self.updatePuzzleList(refreshType: .other)
    }
    
    func filterBar(_ filterBar: PuzzleListQuickFilterBarView, selectedWordFilterDidChange word: String?) {
        self.settingsStorage.puzzleTextFilter = word ?? ""
        self.updatePuzzleList(refreshType: .other)
    }
    
}
