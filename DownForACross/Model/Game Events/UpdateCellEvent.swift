//
//  UpdateCellEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
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

struct UpdateCellEvent: DedupableGameEvent {
    
    var type: String { "updateCell" }
    var eventId: String
    
    let userId: String
    let gameId: String
    let cell: CellCoordinates
    let autocheck: Bool?
    let value: String?
    
    init(payload: [String: Any]) {
        guard let eventId = payload["id"] as? String,
              let params = payload["params"] as? [String: Any],
              let id = params["id"] as? String,
              let coords = params["cell"] as? [String: Any],
              let row = coords["r"] as? NSNumber,
              let cell = coords["c"] as? NSNumber else {
            fatalError()
        }
        self.eventId = eventId
        self.userId = id
        self.cell = CellCoordinates(row: row.intValue, cell: cell.intValue)
        self.autocheck = params["autocheck"] as? Bool
        self.value = params["value"] as? String
        self.gameId = ""
    }
    
    init(userId: String, gameId: String, cell: CellCoordinates, value: String?, autocheck: Bool) {
        self.eventId = UUID().uuidString
        self.userId = userId
        self.gameId = gameId
        self.cell = cell
        self.value = value
        self.autocheck = autocheck
    }
    
    var dedupKey: String {
        return "\(self.type),\(self.cell.row),\(self.cell.cell)"
    }
    
    var paramsDictionary: [String : Any?] {[
        "id": self.userId,
        "cell": [
            "r": self.cell.row,
            "c": self.cell.cell
        ],
        "autocheck": self.autocheck,
        "value": self.value
    ]}
    
}
