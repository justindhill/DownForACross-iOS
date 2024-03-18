//
//  SettingsViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 2/9/24.
//

import UIKit

class SettingsViewController: UIViewController {

    enum Setting: Hashable {
        case editableText(title: String, description: String?, keypath: WritableKeyPath<SettingsStorage, String>)
    }

    let tableView: UITableView
    let settingsStorage: SettingsStorage
    var dataSource: UITableViewDiffableDataSource<Int, Setting>!
    let textFieldReuseIdentifier = "TextFieldReuseIdentifier"

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(settingsStorage: SettingsStorage) {
        self.settingsStorage = settingsStorage
        self.tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false

        super.init(nibName: nil, bundle: nil)

        self.navigationItem.title = "Settings"

        self.dataSource = UITableViewDiffableDataSource(
            tableView: self.tableView,
            cellProvider: { [weak self] tableView, indexPath, setting in
                guard let self else { return nil }
                return self.tableView(tableView, cellForRowAtIndexPath: indexPath, setting: setting)
        })

        var snap = NSDiffableDataSourceSnapshot<Int, Setting>()
        snap.appendSections([0])
        snap.appendItems([
            .editableText(title: "Display name",
                          description: "How you will appear to other players in chat messages and the player list",
                          keypath: \.userDisplayName)
        ], toSection: 0)

        self.dataSource.apply(snap, animatingDifferences: false)
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = .systemBackground
        self.view.addSubview(self.tableView)
        self.tableView.dataSource = self.dataSource
        self.tableView.register(SettingsEditableTextCell.self, forCellReuseIdentifier: self.textFieldReuseIdentifier)

        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath, setting: Setting) -> UITableViewCell {
        switch setting {
            case .editableText(let title, let description, let keypath):
                let textCell = tableView.dequeueReusableCell(withIdentifier: self.textFieldReuseIdentifier, for: indexPath) as! SettingsEditableTextCell
                textCell.settingsStorage = self.settingsStorage
                textCell.title = title
                textCell.details = description
                textCell.keyPath = keypath
                return textCell
        }
    }

}
