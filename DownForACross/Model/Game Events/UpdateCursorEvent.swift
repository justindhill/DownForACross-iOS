//
//  UpdateCursorEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/21/23.
//

import Foundation

struct UpdateCursorEvent {
    
    let id: String
    let timestamp: NSNumber
    let cell: CellCoordinates
    
    init(payload: [String: Any]) {
        guard let params = payload["params"] as? [String: Any],
              let id = params["id"] as? String,
              let timestamp = params["timestamp"] as? NSNumber,
              let coords = params["cell"] as? [String: Any],
              let row = coords["r"] as? NSNumber,
              let cell = coords["c"] as? NSNumber else {
            fatalError("Invalid coodinate update payload")
        }
        
        self.id = id
        self.timestamp = timestamp
        self.cell = CellCoordinates(row: row.intValue, cell: cell.intValue)
    }
    
}
