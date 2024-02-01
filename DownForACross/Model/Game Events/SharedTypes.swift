//
//  SharedTypes.swift
//  DownForACross
//
//  Created by Justin Hill on 12/22/23.
//

import Foundation
import UIKit

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

struct Player {
    var displayName: String = "Unknown player"
    var color: UIColor = .systemGray6
}

struct Cursor {
    var player: Player
    var coordinates: CellCoordinates
}

enum Direction {
    case across
    case down
    
    var opposite: Direction {
        switch self {
            case .across: return .down
            case .down: return .across
        }
    }
}
