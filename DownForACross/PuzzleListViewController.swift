//
//  ViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import UIKit

class PuzzleListViewController: UIViewController, UITableViewDelegate {
    
    let reuseIdentifier: String = "ItemReuseIdentifier"
    
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
    
    let api = API()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Down For a Cross"
        self.tableView.dataSource = self.dataSource
        
        self.view.addSubview(self.tableView)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.reuseIdentifier)
        
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
        guard let puzzle = self.dataSource.itemIdentifier(for: indexPath)?.content else { return }
        let vc = PuzzleViewController(puzzle: puzzle)
        self.navigationController?.pushViewController(vc, animated: true)
    }


}

