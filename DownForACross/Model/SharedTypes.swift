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

    var isFirstColumn: Bool {
        return self.cell == 0
    }

    var isFirstRow: Bool {
        return self.row == 0
    }

    func next(_ direction: Direction) -> CellCoordinates {
        switch direction {
            case .across: CellCoordinates(row: self.row, cell: self.cell + 1)
            case .down: CellCoordinates(row: self.row + 1, cell: self.cell)
        }
    }

    func previous(_ direction: Direction) -> CellCoordinates {
        switch direction {
            case .across: CellCoordinates(row: self.row, cell: self.cell - 1)
            case .down: CellCoordinates(row: self.row - 1, cell: self.cell)
        }
    }
}

struct CellEntry: Equatable, Codable {
    var userId: String
    var value: String
    var correctness: Correctness?

    var isWritable: Bool {
        switch self.correctness {
            case .none: true
            case .some(let correctness): correctness.isWritable
        }
    }
}

enum Correctness: Equatable, Codable {
    case correct
    case incorrect
    case revealed
    case penciled

    fileprivate var isWritable: Bool {
        switch self {
            case .correct, .revealed: return false
            case .incorrect, .penciled: return true
        }
    }
}

struct Player: Hashable, Identifiable {
    private static let defaultColor: UIColor = .clear
    private static let defaultDisplayName: String = "Unknown player"

    static let activityTimeoutInterval: TimeInterval = 60

    var id: String {
        return self.userId
    }
    
    var userId: String
    var displayName: String = Self.defaultDisplayName
    var color: UIColor = Self.defaultColor
    var lastActivityTimeInterval: TimeInterval = Date().timeIntervalSince1970

    var isActive: Bool {
        Date().timeIntervalSince1970 - self.lastActivityTimeInterval < Self.activityTimeoutInterval
    }

    var isComplete: Bool {
        !((self.displayName == Self.defaultDisplayName) || (self.color == Self.defaultColor))
    }

    static func ==(lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id &&
        lhs.userId == rhs.userId &&
        lhs.displayName == rhs.displayName &&
        lhs.color == rhs.color
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.userId)
        hasher.combine(self.displayName)
        hasher.combine(self.color)
    }
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

struct MessageAndPlayer: Hashable, Identifiable {
    let message: ChatEvent
    let playerId: String

    static func == (lhs: MessageAndPlayer, rhs: MessageAndPlayer) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
        
    var id: String {
        return self.message.clientSideMessageId ?? self.message.messageId
    }
}

struct SaveState: Codable {

    var solution: [[CellEntry?]]
    var lastReadMessageTimestamp: TimeInterval

}
