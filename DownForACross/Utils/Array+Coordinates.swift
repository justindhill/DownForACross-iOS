//
//  Array+Coordinates.swift
//  DownForACross
//
//  Created by Justin Hill on 3/28/24.
//

import Foundation

extension Array where Element == [String] {

    subscript(_ coordinates: CellCoordinates) -> String? {
        assert(self.count > coordinates.row, "Subscripted coordinates where row is larger than the grid!")
        let row = self[coordinates.row]
        assert(row.count > coordinates.cell, "Subscripted coordinates where cell is larger than the grid!")
        return row[coordinates.cell]
    }

    var rowCount: Int {
        self.count
    }

    var columnCount: Int {
        self.rowCount == 0 ? 0 : self[0].count
    }

}

extension Array where Element == [CellEntry?] {

    subscript(_ coordinates: CellCoordinates) -> CellEntry? {
        assert(self.count > coordinates.row, "Subscripted coordinates where row is larger than the grid!")
        let row = self[coordinates.row]
        assert(row.count > coordinates.cell, "Subscripted coordinates where cell is larger than the grid!")
        return row[coordinates.cell]
    }

}
