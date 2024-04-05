//
//  UIView+ClosestViewController.swift
//  DownForACross
//
//  Created by Justin Hill on 4/4/24.
//

import UIKit

extension UIView {

    func closestViewController() -> UIViewController? {
        var candidate = self.next
        
        while candidate != nil {
            if let candidate = candidate as? UIViewController {
                return candidate
            } else {
                candidate = candidate?.next
            }
        }

        return nil
    }

}
