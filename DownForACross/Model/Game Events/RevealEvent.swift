//
//  CheckEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 3/12/24.
//

import Foundation

class RevealEvent: GameEvent {
    
    var type: String = "reveal"
    var eventId: String = UUID().uuidString

    var gameId: String
    var cells: [CellCoordinates]
    
    init(gameId: String, cells: [CellCoordinates]) {
        self.gameId = gameId
        self.cells = cells
    }
    
    init(payload: [String: Any]) throws {
        self.gameId = ""
        
        guard let params = payload["params"] as? [String: Any],
              let scope = params["scope"] as? [[String: Any]] else {
            throw NSError(domain: "RevealEventDomain", code: 0)
        }
        
        self.cells = try scope.map({ item in
            guard let row = item["r"] as? Int,
                  let cell = item["c"] as? Int else { throw NSError(domain: "RevealEventDomain", code: 1) }
            return CellCoordinates(row: row, cell: cell)
        })
    }
    
    var paramsDictionary: [String : Any?] {[
        "scope": self.cells.map({[
            "r": $0.row,
            "c": $0.cell
        ]})
    ]}
    
}
