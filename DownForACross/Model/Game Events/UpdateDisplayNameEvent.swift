//
//  UpdateDisplayNameEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation

struct UpdateDisplayNameEvent: DedupableGameEvent {
    
    var type: String { "updateDisplayName" }
    var eventId: String = UUID().uuidString
    
    let userId: String
    let gameId: String
    let displayName: String
    
    init(userId: String, gameId: String, displayName: String) {
        self.userId = userId
        self.gameId = gameId
        self.displayName = displayName
    }
    
    init(payload: [String: Any]) throws {
        self.gameId = ""
        
        guard let params = payload["params"] as? [String: Any],
              let userId = params["id"] as? String,
              let displayName = params["displayName"] as? String else {
            throw NSError(domain: "ChatEvent", code: 0)
        }
        
        self.userId = userId
        self.displayName = displayName
    }
    
    var paramsDictionary: [String : Any?] {[
        "id": self.userId,
        "displayName": self.displayName
    ]}
    
}
