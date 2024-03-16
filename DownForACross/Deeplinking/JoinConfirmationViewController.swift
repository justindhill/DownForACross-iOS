//
//  JoinConfirmationViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 3/15/24.
//

import UIKit

protocol JoinConfirmationViewControllerDelegate: AnyObject {
    func joinConfirmationViewControllerDidSelectJoin(_ viewController: JoinConfirmationViewController)
    func joinConfirmationViewControllerDidSelectClose(_ viewController: JoinConfirmationViewController)
}

class JoinConfirmationViewController: UIViewController {

    weak var delegate: JoinConfirmationViewControllerDelegate?

    let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var joinButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.configuration?.title = "Join"
        button.addTarget(self, action: #selector(joinButtonTapped), for: .primaryActionTriggered)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton(configuration: .plain())
        button.configuration?.image = UIImage(systemName: "xmark.circle.fill")
        button.configuration?.contentInsets = .zero
        button.addTarget(self, action: #selector(closeButtonTapped), for: .primaryActionTriggered)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .tertiaryLabel
        return button
    }()

    let players: [Player]
    let puzzle: Puzzle

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(puzzle: Puzzle, players: [Player]) {
        self.players = players
        self.puzzle = puzzle
        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .pageSheet
        self.sheetPresentationController?.detents = [.medium()]
        self.sheetPresentationController?.prefersGrabberVisible = false
    }

    override func viewDidLoad() {
        self.view.backgroundColor = .systemBackground
        self.view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.textColor = .label
        titleLabel.text = "Join game"
        self.contentStackView.addArrangedSubview(titleLabel)
        self.contentStackView.setCustomSpacing(32, after: titleLabel)

        let puzzleHeadingLabel = self.createHeadingLabel()
        puzzleHeadingLabel.text = "Puzzle"
        self.contentStackView.addArrangedSubview(puzzleHeadingLabel)
        self.contentStackView.setCustomSpacing(4, after: puzzleHeadingLabel)

        let puzzleNameLabel = self.createContentLabel()
        puzzleNameLabel.text = self.puzzle.info.title
        self.contentStackView.addArrangedSubview(puzzleNameLabel)
        self.contentStackView.setCustomSpacing(16, after: puzzleNameLabel)

        let playersHeadingLabel = self.createHeadingLabel()
        playersHeadingLabel.text = "Current players"
        self.contentStackView.addArrangedSubview(playersHeadingLabel)
        self.contentStackView.setCustomSpacing(4, after: playersHeadingLabel)

        let playersLabel = self.createContentLabel()
        playersLabel.text = self.players.map({ $0.displayName }).joined(separator: ", ")
        self.contentStackView.addArrangedSubview(playersLabel)

        self.view.addSubview(self.contentStackView)
        self.view.addSubview(self.joinButton)
        self.view.addSubview(self.closeButton)

        NSLayoutConstraint.activate([
            self.contentStackView.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.contentStackView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            self.contentStackView.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            self.joinButton.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.joinButton.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
            self.joinButton.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            self.closeButton.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            self.closeButton.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    func createHeadingLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }

    func createContentLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }

    @objc func joinButtonTapped() {
        self.delegate?.joinConfirmationViewControllerDidSelectJoin(self)
    }

    @objc func closeButtonTapped() {
        self.delegate?.joinConfirmationViewControllerDidSelectClose(self)
    }

}

