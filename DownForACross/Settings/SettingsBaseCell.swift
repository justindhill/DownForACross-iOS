//
//  SettingsBaseCell.swift
//  DownForACross
//
//  Created by Justin Hill on 3/18/24.
//

import UIKit

class SettingsBaseCell: UITableViewCell {

    var settingsStorage: SettingsStorage!
    var title: String = "" {
        didSet {
            var config = self.contentConfiguration as? UIListContentConfiguration
            config?.text = self.title
            self.contentConfiguration = config
        }
    }
    var details: String? {
        didSet {
            var config = self.contentConfiguration as? UIListContentConfiguration
            config?.secondaryText = self.details
            self.contentConfiguration = config
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        var config = self.defaultContentConfiguration()
        config.secondaryTextProperties.color = .secondaryLabel
        self.contentConfiguration = config
    }


}
