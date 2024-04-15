//
//  PingEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 4/9/24.
//

import Foundation

class PingEvent: DedupableGameEvent {

    var type: String = "addPing"
    var eventId: String = UUID().uuidString
    var userId: String
    var gameId: String
    var cell: CellCoordinates

    var dedupKey: String {
        "\(self.type)-\(self.userId)-\(self.cell.row),\(self.cell.cell)"
    }

    init(userId: String, gameId: String, cell: CellCoordinates) {
        self.userId = userId
        self.gameId = gameId
        self.cell = cell
    }

    init(payload: [String: Any]) throws {
        self.gameId = ""

        guard let params = payload["params"] as? [String: Any],
              let userId = params["id"] as? String,
              let coords = params["cell"] as? [String: Any],
              let row = coords["r"] as? NSNumber,
              let cell = coords["c"] as? NSNumber else {
            throw NSError(domain: "PingEvent", code: 0)
        }

        self.userId = userId
        self.cell = CellCoordinates(row: row.intValue, cell: cell.intValue)
    }

    var paramsDictionary: [String : Any?] {[
        "id": self.userId,
        "cell": [
            "r": self.cell.row,
            "c": self.cell.cell
        ]
    ]}

}
