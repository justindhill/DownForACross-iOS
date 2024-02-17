//
//  ViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit
import WebKit

class PuzzleListViewController: UIViewController, UITableViewDelegate {
    
    let reuseIdentifier: String = "ItemReuseIdentifier"
    static let userIdUserDefaultsKey: String = "UserId"
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
    
    var userId: String?
    let siteInteractor = SiteInteractor()
    let api = API()
    let settingsStorage: SettingsStorage
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(settingsStorage: SettingsStorage) {
        self.settingsStorage = settingsStorage
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Down For a Cross"
        self.navigationItem.backButtonTitle = ""
        self.tableView.dataSource = self.dataSource
        
        self.view.backgroundColor = .systemBackground
                
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.quickFilterBar)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.reuseIdentifier)
        
        self.userId = UserDefaults.standard.string(forKey: Self.userIdUserDefaultsKey)
        if self.userId == nil {
            self.siteInteractor.getUserId { [weak self] userId in
                if let userId {
                    self?.userId = userId
                    UserDefaults.standard.setValue(userId, forKey: Self.userIdUserDefaultsKey)
                    print("got a user id!")
                } else {
                    print("failed to get a user id from the site")
                }
            }
        } else {
            print("got a user id from UserDefaults!")
        }
        
        NSLayoutConstraint.activate([
            self.quickFilterBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.quickFilterBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.quickFilterBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.quickFilterBar.bottomAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.updatePuzzleList()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let puzzleListEntry = self.dataSource.itemIdentifier(for: indexPath),
              let userId = self.userId else { return }
        let vc = PuzzleViewController(puzzleListEntry: puzzleListEntry, userId: userId, siteInteractor: self.siteInteractor, api: self.api)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func updatePuzzleList() {
        Task {
            do {
                self.quickFilterBar.isUserInteractionEnabled = false
                let puzzleList = try await api.getPuzzleList(
                    wordFilter: self.quickFilterBar.selectedWordFilter ?? "",
                    includeMinis: self.quickFilterBar.selectedPuzzleSize.includeMinis,
                    includeStandards: self.quickFilterBar.selectedPuzzleSize.includeStandards)
                self.quickFilterBar.isUserInteractionEnabled = true
                var snapshot = NSDiffableDataSourceSnapshot<Int, PuzzleListEntry>()
                snapshot.appendSections([0])
                snapshot.appendItems(puzzleList.puzzles, toSection: 0)
                await self.dataSource.apply(snapshot, animatingDifferences: false)
            } catch {
                self.quickFilterBar.isUserInteractionEnabled = true
                print(error)
            }
        }
    }

}

extension PuzzleListViewController: PuzzleListQuickFilterBarViewDelegate {
    
    func filterBar(_ filterBar: PuzzleListQuickFilterBarView, selectedSizesDidChange size: PuzzleListQuickFilterBarView.PuzzleSize) {
        self.settingsStorage.puzzleListSizeFilter = size
        self.updatePuzzleList()
    }
    
    func filterBar(_ filterBar: PuzzleListQuickFilterBarView, selectedWordFilterDidChange word: String?) {
        self.settingsStorage.puzzleTextFilter = word ?? ""
        self.updatePuzzleList()
    }
    
}

