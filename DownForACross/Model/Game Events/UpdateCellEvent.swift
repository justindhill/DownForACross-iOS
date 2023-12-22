//
//  UpdateCellEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation

struct UpdateCellEvent {
    
    let id: String
    let cell: CellCoordinates
    let value: String
    
    init(payload: [String: Any]) {
        guard let params = payload["params"] as? [String: Any],
              let id = params["id"] as? String,
              let value = params["value"] as? String,
              let coords = params["cell"] as? [String: Any],
              let row = coords["r"] as? NSNumber,
              let cell = coords["c"] as? NSNumber else {
            fatalError()
        }
        
        self.id = id
        self.cell = CellCoordinates(row: row.intValue, cell: cell.intValue)
        self.value = value
    }
    
}
