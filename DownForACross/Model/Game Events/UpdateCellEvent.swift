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
    
    let userId: String
    let gameId: String
    let cell: CellCoordinates
    let autocheck: Bool?
    let color: UIColor?
    let value: String?
    
    init(payload: [String: Any]) throws {
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

        if let colorString = params["color"] as? String {
            self.color = try UIColor(hslString: colorString)
        } else {
            self.color = nil
        }
    }
    
    init(userId: String, gameId: String, cell: CellCoordinates, value: String?, color: UIColor?, autocheck: Bool) {
        self.eventId = UUID().uuidString
        self.userId = userId
        self.gameId = gameId
        self.cell = cell
        self.value = value
        self.color = color
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
        "color": self.color?.hslString,
        "autocheck": self.autocheck,
        "value": self.value
    ]}
    
}
