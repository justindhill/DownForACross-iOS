//
//  UpdateDisplayNameEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation

struct UpdateDisplayNameEvent: GameEvent {
    
    var type: String { "updateDisplayName" }
    
    let userId: String
    let gameId: String
    let displayName: String
    
    var paramsDictionary: [String : Any?] {[
        "id": self.userId,
        "displayName": self.displayName
    ]}
    
}
