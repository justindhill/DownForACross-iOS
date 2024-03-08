//
//  ViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit
import WebKit
import Combine

class PuzzleListViewController: UIViewController, UITableViewDelegate {
    
    enum RefreshType {
        case pullToRefresh
        case other
    }
    
    let reuseIdentifier: String = "ItemReuseIdentifier"
    
    let emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.refreshControl = self.refreshControl
        return tableView
    }()
    
    lazy var dataSource: UITableViewDiffableDataSource = {
        UITableViewDiffableDataSource<Int, PuzzleListEntry>(tableView: self.tableView) { tableView, indexPath, puzzle in
            let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = puzzle.content.info.title
            config.secondaryText = puzzle.content.info.author
            cell.contentConfiguration = config
            return cell
        }
    }()
    
    lazy var quickFilterBar: PuzzleListQuickFilterBarView = {
        let view = PuzzleListQuickFilterBarView(puzzleSize: self.settingsStorage.puzzleListSizeFilter, wordFilter: self.settingsStorage.puzzleTextFilter)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    var updateTask: AnyCancellable?
    
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
        
        self.view.backgroundColor = .systemBackground
        self.tableView.backgroundColor = .clear
                
        self.view.addSubview(self.emptyStateView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.quickFilterBar)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.reuseIdentifier)
        
        NSLayoutConstraint.activate([
            self.emptyStateView.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.emptyStateView.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            self.emptyStateView.label.centerYAnchor.constraint(equalTo: self.view.layoutMarginsGuide.centerYAnchor),
            self.quickFilterBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.quickFilterBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.quickFilterBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.quickFilterBar.bottomAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.updatePuzzleList(refreshType: .other)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let puzzleListEntry = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.show(puzzleListEntry: puzzleListEntry)
    }
    
    func show(puzzleListEntry: PuzzleListEntry, gameId: String? = nil) {
        let vc = PuzzleViewController(puzzleListEntry: puzzleListEntry,
                                      userId: self.userId,
                                      gameId: gameId,
                                      siteInteractor: self.siteInteractor,
                                      api: self.api,
                                      settingsStorage: self.settingsStorage)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func updatePuzzleList(refreshType: RefreshType) {
        self.updateTask = AnyCancellable(Task {
            do {
                switch refreshType {
                    case .pullToRefresh:
                        self.refreshControl.beginRefreshing()
                    case .other:
                        self.emptyStateView.activityIndicator.isHidden = false
                        self.emptyStateView.activityIndicator.startAnimating()
                }
                
                let puzzleList = try await api.getPuzzleList(
                    wordFilter: self.quickFilterBar.selectedWordFilter ?? "",
                    includeMinis: self.quickFilterBar.selectedPuzzleSize.includeMinis,
                    includeStandards: self.quickFilterBar.selectedPuzzleSize.includeStandards)
                
                self.emptyStateView.activityIndicator.stopAnimating()
                self.emptyStateView.activityIndicator.isHidden = true
                self.refreshControl.endRefreshing()
                
                var snapshot = NSDiffableDataSourceSnapshot<Int, PuzzleListEntry>()
                snapshot.appendSections([0])
                snapshot.appendItems(puzzleList.puzzles, toSection: 0)
                await self.dataSource.apply(snapshot, animatingDifferences: false)
                
                if puzzleList.puzzles.count == 0 {
                    self.emptyStateView.label.text = "No puzzles found"
                    self.emptyStateView.isHidden = false
                } else {
                    self.emptyStateView.isHidden = true
                }
                
            } catch {
                self.emptyStateView.label.text = "Couldn't load the puzzle list"
                self.quickFilterBar.isUserInteractionEnabled = true
                self.emptyStateView.activityIndicator.stopAnimating()
                print(error)
            }
        }.cancel)
    }
    
    @objc func refreshControlDidBeginRefreshing() {
        self.updatePuzzleList(refreshType: .pullToRefresh)
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

