//
//  UpdateDisplayNameEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation

struct UpdateDisplayNameEvent {
    
    let userId: String
    let gameId: String
    let displayName: String
    
    func dictionary() -> [String: Any] {
        [ 
            "event": [
                "id": UUID().uuidString,
                "type": "updateDisplayName",
                "timestamp": [
                    ".sv": "timestamp"
                ],
                "params": [
                    "id": self.userId,
                    "displayName": self.displayName
                ]
            ],
            "gid": self.gameId
        ]
    }
    
}
