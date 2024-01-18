//
//  UpdateColorEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 1/18/24.
//

import Foundation

struct UpdateColorEvent: GameEvent {
    
    
    var type: String = "updateColor"
    
    var gameId: String
    var paramsDictionary: [String : Any?] {
        [:]
    }
    
    init(payload: [String: Any]) {
        self.gameId = ""
    }
    
}
