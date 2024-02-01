//
//  ChatEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 2/1/24.
//

import Foundation

class ChatEvent: GameEvent {
    
    var type: String { "chat" }

    var gameId: String
    var senderId: String
    var senderName: String
    var message: String
    
    
    init(payload: [String: Any]) throws {
        self.gameId = ""
        
        guard let params = payload["params"] as? [String: Any],
              let senderId = params["senderId"] as? String,
              let senderName = params["sender"] as? String,
              let message = params["text"] as? String else {
            throw NSError(domain: "ChatEvent", code: 0)
        }
        
        self.senderId = senderId
        self.senderName = senderName
        self.message = message
    }
    
    var paramsDictionary: [String : Any?] {
        return [:]
    }
    
}
