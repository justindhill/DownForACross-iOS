//
//  PuzzleClueListViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 1/31/24.
//

import UIKit

protocol PuzzleClueListViewControllerDelegate: AnyObject {
    func clueListViewController(_ clueListViewController: PuzzleClueListViewController, didSelectClueAtSequenceIndex sequenceIndex: Int, direction: Direction)
}

extension Direction {
    
    var sectionIndex: Int {
        switch self {
            case .across: 0
            case .down: 1
        }
    }
    
    var sectionTitle: String {
        switch self {
            case .across: "Across"
            case .down: "Down"
        }
    }
}

class PuzzleClueListViewController: UIViewController {
    
    struct ListEntry: Hashable {
        let originalIndex: Int
        let clue: String
    }
    
    static let reuseIdentifier = "ReuseIdentifier"
    static let marginWidth: CGFloat = 8
    
    var delegate: PuzzleClueListViewControllerDelegate?
    
    lazy var dataSource = DataSource<Direction, ListEntry>(tableView: self.tableView, cellProvider: { tableView, indexPath, itemIdentifier in
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath)

        var config = UIListContentConfiguration.cell()
        config.text = "\(itemIdentifier.originalIndex) \(itemIdentifier.clue)"
        config.textProperties.numberOfLines = 0
        cell.contentConfiguration = config
        
        return cell
    })
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.reuseIdentifier)
        return tableView
    }()
    
    let clues: PuzzleClues
    let compactAcrossClues: [ListEntry]
    let compactDownClues: [ListEntry]
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(clues: PuzzleClues) {
        self.clues = clues
        
        self.compactAcrossClues = clues.across.enumerated().compactMap({ $1 != nil ? ListEntry(originalIndex: $0, clue: $1!) : nil })
        self.compactDownClues = clues.down.enumerated().compactMap({ $1 != nil ? ListEntry(originalIndex: $0, clue: $1!) : nil })

        super.init(nibName: nil, bundle: nil)
        
        self.updateContent(animated: false)
        if self.compactAcrossClues.count > 0 {
            self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = dataSource
        self.tableView.backgroundColor = .clear
        self.tableView.layoutMargins = UIEdgeInsets(top: Self.marginWidth, 
                                                    left: Self.marginWidth,
                                                    bottom: Self.marginWidth,
                                                    right: Self.marginWidth)
        self.view.addSubview(self.tableView)
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    func selectClue(atSequenceIndex sequenceIndex: Int, direction: Direction) {
        let candidate = IndexPath(row: sequenceIndex, section: direction.sectionIndex)
        
        if candidate != self.tableView.indexPathForSelectedRow {
            self.tableView.selectRow(at: candidate, animated: true, scrollPosition: .middle)
        }
    }
    
    func updateContent(animated: Bool) {
        var snap = NSDiffableDataSourceSnapshot<Direction, ListEntry>()
        snap.appendSections([.across, .down])
        snap.appendItems(self.compactAcrossClues, toSection: .across)
        snap.appendItems(self.compactDownClues, toSection: .down)
        self.dataSource.apply(snap, animatingDifferences: animated)
    }
    
}

extension PuzzleClueListViewController {
    
    class DataSource<SectionIdentifierType: Hashable, RowIdentifierType: Hashable>: UITableViewDiffableDataSource<Direction, RowIdentifierType> {
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            guard let section = self.sectionIdentifier(for: section) else { return nil }
            return section.sectionTitle
        }
        
    }
    
}

extension PuzzleClueListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let direction: Direction = indexPath.section == 0 ? .across : .down
        self.delegate?.clueListViewController(self, didSelectClueAtSequenceIndex: indexPath.row, direction: direction)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Direction.across.sectionIndex {
            return 30
        } else {
            return 44
        }
    }
}


