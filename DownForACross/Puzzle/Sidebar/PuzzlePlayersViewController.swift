//
//  PuzzlePlayersViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 2/28/24.
//

import UIKit
import Combine

protocol PuzzlePlayersViewControllerDelegate: AnyObject {
    func playersViewControllerDidSelectSendInvite(_ playersViewController: PuzzlePlayersViewController, sourceView: UIView)
}

class PuzzlePlayersViewController: UIViewController {

    static let playerCellReuseIdentifier: String = "PlayerCellReuseIdentifier"
    static let sendInviteCellReuseIdentifier: String = "SendInviteCellReuseIdentifier"
    static let sendInviteUserId: String = "SENDINVITE"

    weak var delegate: PuzzlePlayersViewControllerDelegate?
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layoutMargins = PuzzleSideBarViewController.subviewLayoutMargins
        tableView.register(PlayerCell.self, forCellReuseIdentifier: PuzzlePlayersViewController.playerCellReuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: PuzzlePlayersViewController.sendInviteCellReuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.delegate = self
        
        return tableView
    }()
    
    lazy var dataSource: DataSource<Int, String> = {
        let dataSource = DataSource<Int, String>(tableView: self.tableView) { [weak self] tableView, indexPath, itemIdentifier in
            guard let self else { return UITableViewCell() }
            return self.tableView(tableView, cellForRow: indexPath, itemIdentifier: itemIdentifier)
        }
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }()
    
    var gameClient: GameClient {
        didSet {
            self.playersSubscription = gameClient.playersPublisher
                .assign(to: \.players, on: self)
        }
    }

    var players: [String: Player] {
        didSet {
            print("players changed")
            print(self.players.mapValues(\.isActive))
            self.updateContent(oldPlayers: oldValue, newPlayers: self.players)
        }
    }

    var refreshTimer: Timer?

    var playersSubscription: AnyCancellable!
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(gameClient: GameClient) {
        self.gameClient = gameClient
        self.players = gameClient.players
        super.init(nibName: nil, bundle: nil)
        self.playersSubscription = gameClient.playersPublisher
            .assign(to: \.players, on: self)
    }
    
    override func viewDidLoad() {
        self.view.addSubview(self.tableView)
        
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.bottomAnchor)
        ])

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshContent()
        self.refreshTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(refreshContent), userInfo: nil, repeats: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.refreshTimer?.invalidate()
        self.refreshTimer = nil
    }

    func updateContent(oldPlayers: [String: Player], newPlayers: [String: Player]) {
        let ids = Array(newPlayers.values)
            .filter({ $0.isComplete })
            .sorted(by: { first, second in
                if first.userId == self.gameClient.userId {
                    true
                } else if second.userId == self.gameClient.userId {
                    false
                } else {
                    switch first.displayName.compare(second.displayName) {
                        case .orderedAscending: true
                        case .orderedDescending: false
                        case .orderedSame: first.userId > second.userId
                    }
                }
            })
            .map(\.id)

        let oldSnap = self.dataSource.snapshot()

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])

        ids.forEach { id in
            snapshot.appendItems([id])
            let oldItem = oldPlayers[id]
            let newItem = newPlayers[id]

            if let oldItem, let newItem, oldItem != newItem || oldItem.isActive != newItem.isActive {
                snapshot.reloadItems([id])
            }
        }

        snapshot.appendItems([Self.sendInviteUserId], toSection: 0)

        self.dataSource.apply(snapshot)
    }

    @objc func refreshContent() {
        self.tableView.visibleCells.forEach { cell in
            if let cell = cell as? PlayerCell {
                cell.updateLastSeenTimeLabel()
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRow indexPath: IndexPath, itemIdentifier: String) -> UITableViewCell {
        if itemIdentifier == Self.sendInviteUserId {
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.sendInviteCellReuseIdentifier, for: indexPath)

            var config = UIListContentConfiguration.cell()
            config.image = UIImage(systemName: "square.and.arrow.up")
            config.text = "Invite others"

            cell.contentConfiguration = config
            return cell
        } else {
            guard let item = self.players[itemIdentifier] else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.playerCellReuseIdentifier, for: indexPath) as! PlayerCell
            cell.setPlayer(item, isCurrentUser: (item.userId == self.gameClient.userId))
            
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

}

extension PuzzlePlayersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return false }
        return item == Self.sendInviteUserId
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        self.delegate?.playersViewControllerDidSelectSendInvite(self, sourceView: cell)
    }
    
}

extension PuzzlePlayersViewController {
    
    class DataSource<SectionIdentifierType: Hashable, RowIdentifierType: Hashable>: UITableViewDiffableDataSource<SectionIdentifierType, RowIdentifierType> {
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            if section == 0 {
                return "Players"
            }
            
            return nil
        }
        
    }
    
}
