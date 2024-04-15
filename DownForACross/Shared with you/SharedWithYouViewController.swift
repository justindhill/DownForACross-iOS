//
//  SharedWithYouViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 3/28/24.
//

import UIKit
import SharedWithYou

class SharedWithYouViewController: UIViewController {

    let reuseIdentifier: String = "ReuseIdentifier"

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    lazy var dataSource: SharedWithYouDataSource<String> = {
        let dataSource = SharedWithYouDataSource<String>(tableView: self.tableView,
                                                         cellProvider: { [weak self] tableView, indexPath, identifier in
            guard let self else { return UITableViewCell() }
            return self.tableView(tableView, cellForRowAt: indexPath, identifier: identifier)
        })
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }()

    var highlightCenter: SWHighlightCenter

    let settingsStorage: SettingsStorage
    let gameInfoResolver: SharedGameInfoResolver
    let siteInteractor: SiteInteractor
    let userId: String
    let api: API

    let emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.label.text = "Links you've opened and invites from Messages will appear here"
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    var models: [String: SharedGame] = [:]

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(userId: String, siteInteractor: SiteInteractor, api: API, settingsStorage: SettingsStorage) {
        self.userId = userId
        self.settingsStorage = settingsStorage
        self.siteInteractor = siteInteractor
        self.highlightCenter = SWHighlightCenter()
        self.api = api
        self.gameInfoResolver = SharedGameInfoResolver(userId: userId, settingsStorage: settingsStorage)
        super.init(nibName: nil, bundle: nil)
        
        self.highlightCenter.delegate = self
        self.navigationItem.title = "Shared with You"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.tableView.dataSource = self.dataSource
        self.tableView.delegate = self

        self.tableView.register(SharedGameCell.self, forCellReuseIdentifier: self.reuseIdentifier)

        self.refreshContent()

        self.view.addSubview(self.tableView)
        self.view.addSubview(self.emptyStateView)
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.emptyStateView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.emptyStateView.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.emptyStateView.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor)

        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
            var snapshot = self.dataSource.snapshot()
            let ids = visibleIndexPaths.compactMap({ self.dataSource.itemIdentifier(for: $0) })
            snapshot.reloadItems(ids)

            self.dataSource.apply(snapshot, animatingDifferences: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.refreshContent()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, identifier: String) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as? SharedGameCell,
              let item = self.models[identifier] else {
            return nil
        }

        switch item {
            case .stub(let stubGame):
                cell.titleLabel.text = Array(repeating: "0", count: Int.random(in: 10...20)).joined()
                cell.authorLabel.text = Array(repeating: "0", count: Int.random(in: 10...30)).joined()
                cell.sharingHighlight = stubGame.highlight
                cell.obscuresLabels = true
            case .resolved(let resolvedGame):
                cell.titleLabel.text = resolvedGame.puzzle.info.title
                cell.authorLabel.text = resolvedGame.puzzle.info.author
                cell.sharingHighlight = resolvedGame.highlight
                cell.obscuresLabels = false
        }

        if let completion = self.settingsStorage.gameIdToCompletion[identifier] {
            cell.accessoryView = completion.createAccessoryImageView()
        } else {
            cell.accessoryView = nil
        }

        return cell
    }

    func refreshContent() {
        var models: [String: SharedGame] = [:]
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()

        func updateAfterResolvingGameInfo(_ result: Result<ResolvedSharedGame, NSError>) {
            switch result {
                case .success(var resolvedGame):
                    let highlight = self.models[resolvedGame.gameId]?.highlight
                    resolvedGame.highlight = highlight
                    self.updateItem(resolvedGame)
                case .failure:
                    break
            }
        }

        let recentlyOpenedSharedGames = settingsStorage.recentlyOpenedSharedGames.sorted(using: KeyPathComparator(\.lastOpened, order: .reverse))

        if recentlyOpenedSharedGames.count > 0 {
            snapshot.appendSections([0])
            snapshot.appendItems(recentlyOpenedSharedGames.map { recentlyOpened in
                let item = self.gameInfoResolver.gameInfo(gameId: recentlyOpened.gameId, highlight: nil) { result in
                    updateAfterResolvingGameInfo(result)
                }
                models[recentlyOpened.gameId] = item

                return recentlyOpened.gameId
            }, toSection: 0)
        }

        let messagesItems: [String] = self.highlightCenter.highlights.compactMap { highlight in
            let gameId = highlight.url.lastPathComponent

            if var existingModel = models[gameId] {
                existingModel.highlight = highlight
                models[gameId] = existingModel
                return nil
            }

            let item = self.gameInfoResolver.gameInfo(gameId: gameId, highlight: highlight, resolutionCompletion: { result in
                updateAfterResolvingGameInfo(result)
            })

            models[gameId] = item

            return gameId
        }

        if messagesItems.count > 0 {
            snapshot.appendSections([1])
            snapshot.appendItems(messagesItems, toSection: 1)
        }

        // build the snapshot so the puzzle info gets resolved even if the view isn't loaded yet
        guard self.isViewLoaded else {
            return
        }

        let animated = self.dataSource.numberOfSections(in: self.tableView) > 0 &&
                       self.dataSource.tableView(self.tableView, numberOfRowsInSection: 0) > 0
        self.models = models
        self.dataSource.apply(snapshot, animatingDifferences: animated)

        self.emptyStateView.isHidden = (self.models.count != 0)
    }

    func updateItem(_ item: ResolvedSharedGame) {
        var snapshot = self.dataSource.snapshot()
        self.models[item.id] = .resolved(item)

        if self.isViewLoaded {
            snapshot.reconfigureItems([item.id])
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }

}

extension SharedWithYouViewController: SWHighlightCenterDelegate {

    func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter) {
        self.refreshContent()
    }

}

extension SharedWithYouViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let identifier = self.dataSource.itemIdentifier(for: indexPath),
              let sharedGame = self.models[identifier],
              case .resolved(let resolvedGame) = sharedGame else { return }

        let recentlyOpenedItem = RecentlyOpenedSharedGame(gameId: resolvedGame.gameId, lastOpened: Date())
        if let recentlyOpenedItemIndex = self.settingsStorage.recentlyOpenedSharedGames.firstIndex(where: { $0.gameId == resolvedGame.gameId}) {
            self.settingsStorage.recentlyOpenedSharedGames[recentlyOpenedItemIndex] = recentlyOpenedItem
        } else {
            self.settingsStorage.recentlyOpenedSharedGames.append(recentlyOpenedItem)
        }

        let vc = PuzzleViewController(puzzle: resolvedGame.puzzle,
                                      puzzleId: "",
                                      userId: self.userId,
                                      gameId: resolvedGame.gameId,
                                      siteInteractor: self.siteInteractor,
                                      api: self.api,
                                      settingsStorage: self.settingsStorage)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 {
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .destructive, title: "Remove", handler: { [weak self] _, _, completion in
                    guard let self,
                          let item = self.dataSource.itemIdentifier(for: indexPath),
                          let index = self.settingsStorage.recentlyOpenedSharedGames.firstIndex(where: { $0.gameId == item }) else {
                        completion(false)
                        return
                    }
                    
                    self.settingsStorage.recentlyOpenedSharedGames.remove(at: index)
                    self.refreshContent()
                    completion(true)
                })
            ])
        }

        return nil
    }

}

class SharedWithYouDataSource<ItemIdentifierType: Hashable>: UITableViewDiffableDataSource<Int, ItemIdentifierType> {

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionIdentifier = self.sectionIdentifier(for: section),
                self.numberOfSections(in: tableView) > 1 else { return nil }

        if sectionIdentifier == 0 {
            return "Recently opened"
        } else if sectionIdentifier == 1 {
            return "From Messages"
        } else {
            return nil
        }
    }

}
