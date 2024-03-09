//
//  UINavigationBar+TitleControl.swift
//  DownForACross
//
//  Created by Justin Hill on 3/8/24.
//

import UIKit

extension UINavigationBar {
    
    var titleControl: UIView? {
        return self.findTitleControl(in: self)
    }
    
    private func findTitleControl(in view: UIView) -> UIView? {
        for subview in view.subviews {
            if NSStringFromClass(type(of: subview)) == "_UINavigationBarTitleControl" {
                return subview
            } else if let titleControl = self.findTitleControl(in: subview) {
                return titleControl
            }
        }
        
        return nil
    }
    
}
