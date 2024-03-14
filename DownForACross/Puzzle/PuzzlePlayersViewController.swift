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
    static let sendInviteCellReuseIdentifier: String = "SendInviteCellReuseIdentifier"
    
    weak var delegate: PuzzlePlayersViewControllerDelegate?
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layoutMargins = PuzzleSideBarViewController.subviewLayoutMargins
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: PuzzlePlayersViewController.playerCellReuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: PuzzlePlayersViewController.sendInviteCellReuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.delegate = self
        
        return tableView
    }()
    
    lazy var dataSource: DataSource<Int, Player> = {
        let dataSource = DataSource<Int, Player>(tableView: self.tableView) { tableView, indexPath, itemIdentifier in
            return self.tableView(tableView, cellForRow: indexPath, item: itemIdentifier)
        }
        dataSource.defaultRowAnimation = .fade
        return dataSource
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
        
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.bottomAnchor)
        ])
    }
    
    func updateContent() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Player>()
        snapshot.appendSections([0, 1])
        snapshot.appendItems(self.players, toSection: 0)
        snapshot.appendItems([Player(userId: "SENDINVITE")], toSection: 1)
        
        self.dataSource.apply(snapshot)
    }
    
    func tableView(_ tableView: UITableView, cellForRow indexPath: IndexPath, item: Player) -> UITableViewCell {
        if indexPath.section == 0 {
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
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.sendInviteCellReuseIdentifier, for: indexPath)
            
            var config = UIListContentConfiguration.cell()
            config.image = UIImage(systemName: "square.and.arrow.up")
            config.text = "Send invite"
            
            cell.contentConfiguration = config
            return cell
        }
    }
    
}

extension PuzzlePlayersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.delegate?.playersViewControllerDidSelectSendInvite(self)
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
