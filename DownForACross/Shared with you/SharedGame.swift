//
//  SharedGame.swift
//  DownForACross
//
//  Created by Justin Hill on 3/28/24.
//

import Foundation
import SharedWithYou

enum SharedGame: Hashable {

    case stub(StubSharedGame)
    case resolved(ResolvedSharedGame)

    var id: String {
        self.gameId
    }

    var gameId: String {
        switch self {
            case .resolved(let game): game.gameId
            case .stub(let game): game.gameId
        }
    }

}

struct StubSharedGame: Hashable {

    var id: String {
        return self.gameId
    }

    var gameId: String
    var highlight: SWHighlight? = nil

}

struct ResolvedSharedGame: Hashable, Codable {

    var id: String {
        return self.gameId
    }

    var gameId: String
    var puzzle: Puzzle
    var lastOpened: Date? = nil
    var highlight: SWHighlight? = nil

    enum CodingKeys: CodingKey {
        case gameId
        case puzzle
        case lastOpened
    }

}
