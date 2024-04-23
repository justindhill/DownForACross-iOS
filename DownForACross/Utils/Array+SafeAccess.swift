//
//  Array+SafeAccess.swift
//  DownForACross
//
//  Created by Justin Hill on 4/23/24.
//

import Foundation

extension Array where Element == String? {

    subscript(safe index: Int) -> String? {
        if index > self.count - 1 {
            return .none
        }

        return self[index]
    }

}
