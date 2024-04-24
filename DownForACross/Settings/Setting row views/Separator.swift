//
//  Separator.swift
//  DownForACross
//
//  Created by Justin Hill on 4/24/24.
//

import UIKit

extension SettingsViewController {

    class Separator: UIView {
        let lineLayer: CALayer = CALayer()

        override func didMoveToWindow() {
            if let screen = self.window?.screen {
                self.heightConstraint.constant = 1 / screen.scale
            }
        }

        lazy var heightConstraint: NSLayoutConstraint = self.heightAnchor.constraint(equalToConstant: 1)

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override init(frame: CGRect) {
            super.init(frame: frame)

            self.layoutMargins = BaseSettingView.layoutMargins
            NSLayoutConstraint.activate([
                self.heightConstraint
            ])

            self.layer.addSublayer(self.lineLayer)
        }

        override func layoutSublayers(of layer: CALayer) {
            self.lineLayer.backgroundColor = UIColor.systemFill.cgColor
            self.lineLayer.frame = CGRect(x: self.layoutMargins.left,
                                          y: 0,
                                          width: self.frame.size.width - self.layoutMargins.left,
                                          height: self.frame.size.height)
        }
    }

}
