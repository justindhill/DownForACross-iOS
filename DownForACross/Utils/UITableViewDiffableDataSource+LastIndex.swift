//
//  UITableViewDiffableDataSource+LastIndex.swift
//  DownForACross
//
//  Created by Justin Hill on 3/26/24.
//

import UIKit

extension UITableViewDiffableDataSource {

    func lastIndexPath(in tableView: UITableView) -> IndexPath? {
        let lastSection = self.numberOfSections(in: tableView) - 1
        guard lastSection >= 0 else { return nil }

        let lastRow = self.tableView(tableView, numberOfRowsInSection: lastSection) - 1
        guard lastRow >= 0 else { return nil }

        return IndexPath(row: lastRow, section: lastSection)
    }

}
