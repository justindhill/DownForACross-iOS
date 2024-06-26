//
//  ChatEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 2/1/24.
//

import Foundation

class ChatEvent: UserEvent {

    var type: String { "chat" }
    var eventId: String = UUID().uuidString

    var timestamp: TimeInterval
    var messageId: String
    var gameId: String
    var senderId: String
    var senderName: String
    var message: String
    var clientSideMessageId: String?

    var userId: String {
        return senderId
    }

    init(payload: [String: Any]) throws {
        self.gameId = ""
        
        guard let params = payload["params"] as? [String: Any],
              let timestamp = payload["timestamp"] as? TimeInterval,
              let senderId = params["senderId"] as? String,
              let senderName = params["sender"] as? String,
              let message = params["text"] as? String,
              let messageId = payload["id"] as? String else {
            throw NSError(domain: "ChatEvent", code: 0)
        }
        
        self.timestamp = timestamp / 1000
        self.senderId = senderId
        self.senderName = senderName
        self.message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        self.messageId = messageId
        self.clientSideMessageId = params["clientSideMessageId"] as? String
    }
    
    init(gameId: String, senderId: String, senderName: String, message: String) {
        self.timestamp = Date().timeIntervalSince1970
        self.senderId = senderId
        self.senderName = senderName
        self.message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        self.gameId = gameId
        self.messageId = ""
        self.clientSideMessageId = UUID().uuidString
    }
    
    var paramsDictionary: [String : Any?] {
        return [
            "senderId": self.senderId,
            "sender": self.senderName,
            "text": self.message,
            "clientSideMessageId": self.clientSideMessageId
        ]
    }
    
}
