//
//  UpdateColorEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 1/18/24.
//

import UIKit
import RegexBuilder

struct UpdateColorEvent: DedupableGameEvent {
    
    var timestamp: TimeInterval
    var type: String = "updateColor"
    var eventId: String = UUID().uuidString
    
    var gameId: String
    var userId: String
    var color: UIColor
    
    init(payload: [String: Any]) throws {
        self.gameId = ""
        guard let params = payload["params"] as? [String: Any],
              let timestamp = payload["timestamp"] as? TimeInterval,
              let userId = params["id"] as? String,
              let hslString = params["color"] as? String else {
            throw NSError(domain: "UpdateColorEventErrorDomain", code: 0)
        }
        
        self.timestamp = timestamp / 1000
        self.userId = userId
        self.color = try UIColor(hslString: hslString)
    }
    
    init(gameId: String, userId: String, color: UIColor) {
        self.timestamp = Date().timeIntervalSince1970
        self.gameId = gameId
        self.userId = userId
        self.color = color
    }
    
    var paramsDictionary: [String : Any?] {[
        "id": self.userId,
        "color": self.color.hslString
    ]}
    
}
