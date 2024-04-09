//
//  GameEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 4/9/24.
//

import Foundation

protocol GameEvent {
    var eventId: String { get }
    var gameId: String { get }
    var type: String { get }
    var paramsDictionary: [String: Any?] { get }
    func emitPayload() -> [String: Any]
}

protocol DedupableGameEvent: GameEvent {
    var userId: String { get }
    var dedupKey: String { get }
}

extension DedupableGameEvent {
    var dedupKey: String {
        return self.type
    }
}

extension GameEvent {
    func eventPayload() -> [String: Any] {
        [
            "id": self.eventId,
            "type": self.type,
            "timestamp": [
                ".sv": "timestamp"
            ],
            "params": self.paramsDictionary
        ]
    }

    func emitPayload() -> [String: Any] {
        [
            "event": self.eventPayload(),
            "gid": self.gameId
        ]
    }
}
