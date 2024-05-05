//
//  QuickFiltersViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 4/24/24.
//

import UIKit

class QuickFiltersViewController: UIViewController, UITableViewDelegate {

    enum Section {
        case filters
        case newFilter
    }

    let existingFilterReuseIdentifier = "ExistingFilterReuseIdentifier"
    let newFilterReuseIdentifier = "NewFilterReuseIdentifier"

    let placeholderString: NSAttributedString = {
        let textAttachmentString = NSMutableAttributedString(
            string: "\(UnicodeScalar(NSTextAttachment.character)!)",
            attributes: [
                .attachment: NSTextAttachment(image: UIImage(systemName: "plus.circle")!),
                .foregroundColor: UIColor.systemBlue
            ])
        textAttachmentString.append(NSAttributedString(string: " Add a filter", attributes: [
            .foregroundColor: UIColor.systemBlue
        ]))

        return textAttachmentString
    }()
    var textInputCanceled: Bool = false

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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.existingFilterReuseIdentifier)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.newFilterReuseIdentifier)

        self.updateEditButton()

        self.view.addSubview(self.tableView)
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        self.tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))

        self.updateContent(animated: false)
    }

    @objc func endEditing() {
        self.textInputCanceled = true
        self.view.endEditing(true)
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
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.filters, .newFilter])
        snapshot.appendItems(self.entries, toSection: .filters)
        snapshot.appendItems(["new"], toSection: .newFilter)
        self.dataSource.apply(snapshot, animatingDifferences: animated)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, item: String) -> UITableViewCell {
        guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return UITableViewCell() }
        switch section {
            case .filters:
                let cell = tableView.dequeueReusableCell(withIdentifier: self.existingFilterReuseIdentifier, for: indexPath)

                var config = UIListContentConfiguration.cell()
                config.text = item
                cell.contentConfiguration = config
                cell.showsReorderControl = true

                return cell

            case .newFilter:
                let cell = tableView.dequeueReusableCell(withIdentifier: self.newFilterReuseIdentifier, for: indexPath)
                self.configureTextFieldCell(cell)
                return cell
        }

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

    func configureTextFieldCell(_ cell: UITableViewCell) {
        guard cell.contentView.subviews.firstIndex(where: { $0 is UITextField }) == nil else { return }

        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self

        textField.returnKeyType = .done
        textField.attributedPlaceholder = self.placeholderString

        cell.contentView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            textField.topAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.topAnchor),
            textField.bottomAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    class DataSource: UITableViewDiffableDataSource<Section, String> {

        var orderUpdateBlock: ((Int, Int) -> Void)?
        var deleteBlock: ((Int) -> Void)?

        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            guard let section = self.sectionIdentifier(for: indexPath.section) else { return false }
            return section == .filters
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

extension QuickFiltersViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textInputCanceled = false
        self.endEditing()
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.attributedPlaceholder = nil
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.contains("\n") {
            return false
        }

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        textField.attributedPlaceholder = self.placeholderString

        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), text.count > 0 else { return }
        self.entries.append(text)
        textField.text = nil
        self.updateContent(animated: true)
    }

}
