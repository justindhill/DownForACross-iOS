//
//  UpdateCellEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation

protocol GameEvent {
    var gameId: String { get }
    var type: String { get }
    var paramsDictionary: [String: Any?] { get }
    func eventPayload() -> [String: Any]
}

extension GameEvent {
    func eventPayload() -> [String: Any] {
        [
            "event": [
                "id": UUID().uuidString,
                "type": self.type,
                "timestamp": [
                    ".sv": "timestamp"
                ],
                "params": self.paramsDictionary
            ],
            "gid": self.gameId
        ]
    }
}

struct UpdateCellEvent: GameEvent {
    
    var type: String { "updateCell" }
    
    let userId: String
    let gameId: String
    let cell: CellCoordinates
    let autocheck: Bool?
    let value: String?
    
    init(payload: [String: Any]) {
        guard let params = payload["params"] as? [String: Any],
              let id = params["id"] as? String,
              let coords = params["cell"] as? [String: Any],
              let row = coords["r"] as? NSNumber,
              let cell = coords["c"] as? NSNumber else {
            fatalError()
        }
        self.userId = id
        self.cell = CellCoordinates(row: row.intValue, cell: cell.intValue)
        self.autocheck = params["autocheck"] as? Bool
        self.value = params["value"] as? String
        self.gameId = ""
    }
    
    init(userId: String, gameId: String, cell: CellCoordinates, value: String?, autocheck: Bool) {
        self.userId = userId
        self.gameId = gameId
        self.cell = cell
        self.value = value
        self.autocheck = autocheck
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
