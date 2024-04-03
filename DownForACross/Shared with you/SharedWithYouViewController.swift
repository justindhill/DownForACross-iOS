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

    lazy var dataSource: SharedWithYouDataSource<Int, String> = {
        let dataSource = SharedWithYouDataSource<Int, String>(tableView: self.tableView,
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
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
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

        return cell
    }

    func refreshContent() {
        var models: [String: SharedGame] = [:]
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0, 1])

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
        snapshot.appendItems(recentlyOpenedSharedGames.map { recentlyOpened in
            let item = self.gameInfoResolver.gameInfo(gameId: recentlyOpened.gameId, highlight: nil) { result in
                updateAfterResolvingGameInfo(result)
            }
            models[recentlyOpened.gameId] = item

            return recentlyOpened.gameId
        }, toSection: 0)

        snapshot.appendItems(self.highlightCenter.highlights.compactMap { highlight in
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
        }, toSection: 1)

        // build the snapshot so the puzzle info gets resolved even if the view isn't loaded yet
        guard self.isViewLoaded else {
            return
        }

        let animated = self.dataSource.numberOfSections(in: self.tableView) > 0 &&
                       self.dataSource.tableView(self.tableView, numberOfRowsInSection: 0) > 0
        self.models = models
        self.dataSource.apply(snapshot, animatingDifferences: animated)
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

}

class SharedWithYouDataSource<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> {

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.tableView(tableView, numberOfRowsInSection: 0) > 0 {
            if section == 0 {
                return "Recently opened"
            } else if section == 1 {
                return "From Messages"
            }
        }

        return nil
    }

}