//
//  NSLayoutConstraint+Priority.swift
//  DownForACross
//
//  Created by Justin Hill on 4/5/24.
//

import UIKit

extension NSLayoutConstraint {

    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }

}
