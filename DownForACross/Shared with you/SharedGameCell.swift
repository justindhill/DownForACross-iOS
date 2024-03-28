//
//  SharedGameCell.swift
//  DownForACross
//
//  Created by Justin Hill on 3/28/24.
//

import UIKit
import SharedWithYou

class SharedGameCell: UITableViewCell {

    private let attributionView: SWAttributionView = SWAttributionView()
    var sharingHighlight: SWHighlight? {
        didSet {
            if let sharingHighlight {
                self.attributionView.highlight = sharingHighlight
                self.attributionView.isHidden = false
            } else {
                self.attributionView.highlight = sharingHighlight
                self.attributionView.isHidden = true
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.attributionView.translatesAutoresizingMaskIntoConstraints = false
        self.attributionView.preferredMaxLayoutWidth = 150
        self.attributionView.horizontalAlignment = .trailing
    }

    override func layoutSubviews() {
        if self.attributionView.superview == nil {
            self.contentView.addSubview(self.attributionView)
            NSLayoutConstraint.activate([
                self.attributionView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
                self.attributionView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
        }

        super.layoutSubviews()
    }

}
