//
//  SharedTypes.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation

struct CellCoordinates: Equatable {
    var row: Int
    var cell: Int
}

struct CellEntry: Equatable {
    var userId: String
    var value: String
    var correctness: Correctness?
}

enum Correctness: Equatable {
    case correct
    case incorrect
}
