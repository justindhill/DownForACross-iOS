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

    lazy var dataSource: UITableViewDiffableDataSource<Int, SharedGame> = {
        return UITableViewDiffableDataSource(tableView: self.tableView,
                                             cellProvider: { [weak self] tableView, indexPath, item in
            guard let self else { return nil }
            return self.tableView(tableView, cellForRowAt: indexPath, item: item)
        })
    }()

    var settingsStorage: SettingsStorage
    var highlightCenter: SWHighlightCenter

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(settingsStorage: SettingsStorage) {
        self.settingsStorage = settingsStorage
        self.highlightCenter = SWHighlightCenter()
        super.init(nibName: nil, bundle: nil)
        
        self.highlightCenter.delegate = self
        self.navigationItem.title = "Shared with You"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.tableView.dataSource = self.dataSource

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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, item: SharedGame) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as? SharedGameCell else {
            return nil
        }

        cell.sharingHighlight = item.highlight

        var config = cell.defaultContentConfiguration()
        config.text = item.gameId
        cell.contentConfiguration = config

        return cell
    }

    func refreshContent() {
        guard self.isViewLoaded else {
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, SharedGame>()
        snapshot.appendSections([0])
        snapshot.appendItems(self.highlightCenter.highlights.map({ SharedGame(gameId: $0.url.lastPathComponent, highlight: $0) }),
                             toSection: 0)

        let animated = self.dataSource.numberOfSections(in: self.tableView) > 0 &&
                       self.dataSource.tableView(self.tableView, numberOfRowsInSection: 0) > 0
        self.dataSource.apply(snapshot, animatingDifferences: animated)
    }

}

extension SharedWithYouViewController: SWHighlightCenterDelegate {

    func highlightCenterHighlightsDidChange(_ highlightCenter: SWHighlightCenter) {
        self.refreshContent()
    }

}
