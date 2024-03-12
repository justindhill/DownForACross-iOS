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

struct CellEntry: Equatable, Codable {
    var userId: String
    var value: String
    var correctness: Correctness?
}

enum Correctness: Equatable, Codable {
    case correct
    case incorrect
    case revealed
    
    var writable: Bool {
        switch self {
            case .correct, .revealed: return false
            case .incorrect: return true
        }
    }
}

extension Optional where Wrapped == Correctness {

}

struct Player: Hashable, Identifiable {
    var id: String {
        return self.userId
    }
    
    var userId: String
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

struct MessageAndPlayer: Hashable, Identifiable {
    let message: ChatEvent
    let player: Player
    
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
