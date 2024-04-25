//
//  QuickFiltersViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 4/24/24.
//

import UIKit

class QuickFiltersViewController: UIViewController, UITableViewDelegate {

    let reuseIdentifier = "ReuseIdentifier"
    var entries: [String] {
        didSet {
            self.settingsStorage.quickFilterTerms = entries
        }
    }

    let settingsStorage: SettingsStorage

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = false
        return tableView
    }()

    lazy var dataSource: DataSource = {
        let dataSource = DataSource(tableView: self.tableView) { [weak self] tableView, indexPath, itemIdentifier in
            guard let self else { return UITableViewCell() }
            return self.tableView(tableView, cellForRowAt: indexPath, item: itemIdentifier)
        }

        dataSource.orderUpdateBlock = { [weak self] source, destination in
            guard let self, source != destination else { return }
            let finalDestination = source < destination ? destination + 1 : destination
            self.entries.move(fromOffsets: IndexSet(integer: source), toOffset: finalDestination)
            print(self.entries)
        }

        dataSource.deleteBlock = { [weak self] removeAt in
            self?.entries.remove(at: removeAt)
        }

        return dataSource
    }()

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(settingsStorage: SettingsStorage) {
        self.settingsStorage = settingsStorage
        self.entries = settingsStorage.quickFilterTerms
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = "Quick filters"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemGroupedBackground
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.reuseIdentifier)

        self.updateEditButton()

        self.view.addSubview(self.tableView)
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        self.updateContent(animated: false)
    }

    func updateEditButton() {
        if self.tableView.isEditing {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(editButtonTapped))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonTapped))
        }
    }

    @objc func editButtonTapped() {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true) 
        self.updateEditButton()
    }

    func updateContent(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(self.entries, toSection: 0)
        self.dataSource.apply(snapshot, animatingDifferences: animated)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, item: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath)

        var config = UIListContentConfiguration.cell()
        config.text = item
        cell.contentConfiguration = config
        cell.showsReorderControl = true

        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [
            UIContextualAction(style: .destructive, title: "Remove", handler: { [weak self] _, _, completion in
                guard let self,
                      let item = self.dataSource.itemIdentifier(for: indexPath),
                      let index = self.entries.firstIndex(where: { $0 == item }) else {
                    completion(false)
                    return
                }

                self.entries.remove(at: index)
                self.updateContent(animated: true)
                completion(true)
            })
        ])
    }

    class DataSource: UITableViewDiffableDataSource<Int, String> {

        var orderUpdateBlock: ((Int, Int) -> Void)?
        var deleteBlock: ((Int) -> Void)?

        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return true
        }

        override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            self.orderUpdateBlock?(sourceIndexPath.row, destinationIndexPath.row)
            super.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        }

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            guard let item = self.itemIdentifier(for: indexPath) else { return }
            if editingStyle == .delete {
                self.deleteBlock?(indexPath.row)
            }

            var snapshot = self.snapshot()
            snapshot.deleteItems([item])
            self.apply(snapshot)
        }

    }

}
