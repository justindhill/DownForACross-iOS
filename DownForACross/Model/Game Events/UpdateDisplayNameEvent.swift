//
//  UpdateDisplayNameEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation

struct UpdateDisplayNameEvent: DedupableGameEvent {
    
    var timestamp: TimeInterval
    var type: String { "updateDisplayName" }
    var eventId: String = UUID().uuidString
    
    let userId: String
    let gameId: String
    let displayName: String
    
    init(userId: String, gameId: String, displayName: String) {
        self.timestamp = Date().timeIntervalSince1970
        self.userId = userId
        self.gameId = gameId
        self.displayName = displayName
    }
    
    init(payload: [String: Any]) throws {
        self.gameId = ""
        
        guard let params = payload["params"] as? [String: Any],
              let timestamp = payload["timestamp"] as? TimeInterval,
              let userId = params["id"] as? String,
              let displayName = params["displayName"] as? String else {
            throw NSError(domain: "ChatEvent", code: 0)
        }
        
        self.timestamp = timestamp / 1000
        self.userId = userId
        self.displayName = displayName
    }
    
    var paramsDictionary: [String : Any?] {[
        "id": self.userId,
        "displayName": self.displayName
    ]}
    
}
