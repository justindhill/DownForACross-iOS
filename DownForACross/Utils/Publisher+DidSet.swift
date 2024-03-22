//
//  Publisher+DidSet.swift
//  DownForACross
//
//  Created by Justin Hill on 3/21/24.
//

import Combine
import Foundation

extension Published.Publisher {

    var didSet: AnyPublisher<Value, Never> {
        self.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

}
