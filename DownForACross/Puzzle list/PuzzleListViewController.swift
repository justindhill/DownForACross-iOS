//
//  ViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit
import WebKit
import Combine

class PuzzleListViewController: UIViewController, UITableViewDelegate, UITableViewDataSourcePrefetching {
    
    enum Section: Int {
        case puzzles
        case loadMore
    }
    
    enum RefreshType {
        case pullToRefresh
        case loadMore
        case other
    }
    
    let listItemReuseIdentifier: String = "ItemReuseIdentifier"
    let loadingSpinnerReuseIdentifier: String = "LoadingSpinnerReuseIdentifier"
    let reachedEndReuseIdentifier: String = "ReachedEndReuseIdentifier"
    
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
        let view = PuzzleListQuickFilterBarView(puzzleSize: self.settingsStorage.puzzleListSizeFilter, wordFilter: self.settingsStorage.puzzleTextFilter)
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
        let vc = PuzzleViewController(puzzle: puzzleListEntry.content,
                                      puzzleId: puzzleListEntry.pid,
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
                        self.page = 0
                        self.refreshControl.beginRefreshing()
                    case .other:
                        self.page = 0
                        self.emptyStateView.activityIndicator.isHidden = false
                        self.emptyStateView.activityIndicator.startAnimating()
                    case .loadMore:
                        self.page += 1
                        break
                }
                
                let puzzleList = try await api.getPuzzleList(
                    page: self.page,
                    wordFilter: self.quickFilterBar.selectedWordFilter ?? "",
                    includeMinis: self.quickFilterBar.selectedPuzzleSize.includeMinis,
                    includeStandards: self.quickFilterBar.selectedPuzzleSize.includeStandards,
                    limit: self.pageLimit)
                
                self.hasReachedLastPage = puzzleList.puzzles.count < self.pageLimit
                
                self.emptyStateView.activityIndicator.stopAnimating()
                self.emptyStateView.activityIndicator.isHidden = true
                self.refreshControl.endRefreshing()
                
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
                if refreshType == .other {
                    tableView.contentOffset = .zero
                }
                
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

