//
//  UpdateCursorEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/21/23.
//

import Foundation

struct UpdateCursorEvent: UserEvent {
    
    var type: String { "updateCursor" }
    var eventId: String = UUID().uuidString
    
    let userId: String
    let gameId: String
    let timestamp: TimeInterval
    let cell: CellCoordinates
    
    init(payload: [String: Any]) {
        guard let params = payload["params"] as? [String: Any],
              let id = params["id"] as? String,
              let timestamp = payload["timestamp"] as? TimeInterval,
              let coords = params["cell"] as? [String: Any],
              let row = coords["r"] as? NSNumber,
              let cell = coords["c"] as? NSNumber else {
            fatalError("Invalid coodinate update payload")
        }
        
        self.userId = id
        self.gameId = ""
        self.timestamp = timestamp / 1000
        self.cell = CellCoordinates(row: row.intValue, cell: cell.intValue)
    }
    
    init(userId: String, gameId: String, coordinates: CellCoordinates) {
        self.userId = userId
        self.gameId = gameId
        self.cell = coordinates
        self.timestamp = Date().timeIntervalSince1970
    }
    
    var paramsDictionary: [String : Any?] {[
        "id": self.userId,
        "timestamp": self.timestamp,
        "cell": [
            "r": self.cell.row,
            "c": self.cell.cell
        ]
    ]}
    
}
