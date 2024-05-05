//
//  PlayerCell.swift
//  DownForACross
//
//  Created by Justin Hill on 5/4/24.
//

import UIKit

class PlayerCell: UITableViewCell {

    private static let relativeTimeFormatter = RelativeDateTimeFormatter()

    private(set) var isCurrentUser: Bool = false
    private(set) var player: Player = Player(userId: "empty") {
        didSet {
            self.updatePlayerContent()
        }
    }

    func setPlayer(_ player: Player, isCurrentUser: Bool) {
        self.isCurrentUser = isCurrentUser
        self.player = player
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let imageView = UIImageView(image: UIImage(systemName: "circle.fill")?.withRenderingMode(.alwaysTemplate))
        self.accessoryView = imageView
    }
    

    func updatePlayerContent() {
        var contentConfig: UIListContentConfiguration
        if let currentConfig = self.contentConfiguration as? UIListContentConfiguration {
            contentConfig = currentConfig
        } else {
            contentConfig = UIListContentConfiguration.cell()
        }

        contentConfig.text = self.player.displayName
        contentConfig.secondaryTextProperties.color = .secondaryLabel

        self.accessoryView?.tintColor = player.color
        self._updateLastSeenTimeLabel(contentConfig: &contentConfig)
        self.contentConfiguration = contentConfig
    }

    func updateLastSeenTimeLabel() {
        guard var contentConfig = self.contentConfiguration as? UIListContentConfiguration else { return }
        _updateLastSeenTimeLabel(contentConfig: &contentConfig)
        self.contentConfiguration = contentConfig
    }

    private func _updateLastSeenTimeLabel(contentConfig: inout UIListContentConfiguration) {
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        contentConfig.secondaryTextProperties.font = font
        if self.isCurrentUser {
            contentConfig.secondaryText = "You"
        } else if self.player.isActive {
            contentConfig.secondaryText = "Active now"
        } else {
            let activeTime = Date(timeIntervalSince1970: self.player.lastActivityTimeInterval)
            let now = Date()

            contentConfig.secondaryText = "Seen " + Self.relativeTimeFormatter.localizedString(for: activeTime, relativeTo: now)
            contentConfig.secondaryTextProperties.font = UIFont.italicSystemFont(ofSize: font.pointSize)
        }
    }

}

