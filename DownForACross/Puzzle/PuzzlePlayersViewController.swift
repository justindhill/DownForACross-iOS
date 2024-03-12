//
//  PuzzlePlayersViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 2/28/24.
//

import UIKit
import Combine

protocol PuzzlePlayersViewControllerDelegate: AnyObject {
    func playersViewControllerDidSelectSendInvite(_ playersViewController: PuzzlePlayersViewController)
}

class PuzzlePlayersViewController: UIViewController {
    
    static let playerCellReuseIdentifier: String = "PlayerCellReuseIdentifier"
    
    weak var delegate: PuzzlePlayersViewControllerDelegate?
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layoutMargins = PuzzleSideBarViewController.subviewLayoutMargins
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: PuzzlePlayersViewController.playerCellReuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        
        return tableView
    }()
    
    lazy var dataSource: DataSource<Int, Player> = {
        let dataSource = DataSource<Int, Player>(tableView: self.tableView) { tableView, indexPath, itemIdentifier in
            return self.tableView(tableView, cellForRow: indexPath, item: itemIdentifier)
        }
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }()
    
    lazy var inviteButton: UIButton = {
        let button = UIButton(configuration: .gray())
        button.configuration?.title = "Send invite"
        button.addTarget(self, action: #selector(inviteButtonTapped), for: .primaryActionTriggered)
        button.sizeToFit()
        
        return button
    }()
    
    let gameClient: GameClient
    var players: [Player] {
        didSet {
            self.updateContent()
        }
    }
    
    var playersSubscription: AnyCancellable!
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(gameClient: GameClient) {
        self.gameClient = gameClient
        self.players = Array(gameClient.players.values)
        super.init(nibName: nil, bundle: nil)
        self.playersSubscription = gameClient.$players
            .map({ Array($0.values) })
            .assign(to: \.players, on: self)
    }
    
    override func viewDidLoad() {
        self.view.addSubview(self.tableView)
        self.tableView.tableFooterView = self.inviteButton
        
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.bottomAnchor)
        ])
    }
    
    @objc func inviteButtonTapped() {
        self.delegate?.playersViewControllerDidSelectSendInvite(self)
    }
    
    func updateContent() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Player>()
        snapshot.appendSections([0])
        snapshot.appendItems(self.players, toSection: 0)
        
        self.dataSource.apply(snapshot)
    }
    
    func tableView(_ tableView: UITableView, cellForRow indexPath: IndexPath, item: Player) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.playerCellReuseIdentifier, for: indexPath)
        
        var config = UIListContentConfiguration.cell()
        config.text = item.displayName
        if item.userId == self.gameClient.userId {
            config.secondaryTextProperties.color = .secondaryLabel
            config.secondaryText = "You"
        }
        let accessoryImageView: UIImageView
        if let imageView = cell.accessoryView as? UIImageView {
            accessoryImageView = imageView
        } else {
            let imageView = UIImageView(image: UIImage(systemName: "circle.fill")?.withRenderingMode(.alwaysTemplate))
            cell.accessoryView = imageView
            accessoryImageView = imageView
        }
        
        accessoryImageView.tintColor = item.color
        
        cell.contentConfiguration = config
        
        return cell
    }
    
}

extension PuzzlePlayersViewController {
    
    class DataSource<SectionIdentifierType: Hashable, RowIdentifierType: Hashable>: UITableViewDiffableDataSource<SectionIdentifierType, RowIdentifierType> {
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return "Players"
        }
        
    }
    
}
