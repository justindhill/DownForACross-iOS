//
//  UpdateCellEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import UIKit

struct UpdateCellEvent: DedupableGameEvent {

    
    var type: String { "updateCell" }
    var eventId: String
    
    var timestamp: TimeInterval
    let userId: String
    let gameId: String
    let cell: CellCoordinates
    let autocheck: Bool?
    let pencil: Bool?
    let value: String?
    
    init(payload: [String: Any]) throws {
        guard let eventId = payload["id"] as? String,
              let timestamp = payload["timestamp"] as? TimeInterval,
              let params = payload["params"] as? [String: Any],
              let id = params["id"] as? String,
              let coords = params["cell"] as? [String: Any],
              let row = coords["r"] as? NSNumber,
              let cell = coords["c"] as? NSNumber else {
            fatalError()
        }
        self.timestamp = timestamp / 1000
        self.eventId = eventId
        self.userId = id
        self.cell = CellCoordinates(row: row.intValue, cell: cell.intValue)
        self.autocheck = params["autocheck"] as? Bool
        self.pencil = params["pencil"] as? Bool
        self.value = params["value"] as? String
        self.gameId = ""
    }
    
    init(userId: String, gameId: String, cell: CellCoordinates, value: String?, color: UIColor?, autocheck: Bool, pencil: Bool) {
        self.eventId = UUID().uuidString
        self.timestamp = Date().timeIntervalSince1970
        self.userId = userId
        self.gameId = gameId
        self.cell = cell
        self.value = value
        self.autocheck = autocheck
        self.pencil = pencil
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
        "pencil": self.pencil,
        "autocheck": self.autocheck,
        "value": self.value
    ]}
    
}
