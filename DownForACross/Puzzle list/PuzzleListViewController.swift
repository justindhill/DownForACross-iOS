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
    
    var userId: String?
    let siteInteractor = SiteInteractor()
    let api = API()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Down For a Cross"
        self.navigationItem.backButtonTitle = ""
        self.tableView.dataSource = self.dataSource
        
        self.view.addSubview(self.tableView)
        
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
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        Task {
            do {
                let puzzleList = try await api.getPuzzleList()
                var snapshot = NSDiffableDataSourceSnapshot<Int, PuzzleListEntry>()
                snapshot.appendSections([0])
                snapshot.appendItems(puzzleList.puzzles, toSection: 0)
                await self.dataSource.apply(snapshot)                
            } catch {
                print(error)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let puzzleListEntry = self.dataSource.itemIdentifier(for: indexPath),
              let userId = self.userId else { return }
        let vc = PuzzleViewController(puzzleListEntry: puzzleListEntry, userId: userId, siteInteractor: self.siteInteractor, api: self.api)
        self.navigationController?.pushViewController(vc, animated: true)
    }


}

