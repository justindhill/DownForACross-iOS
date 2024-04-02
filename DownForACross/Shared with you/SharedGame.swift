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

    var highlight: SWHighlight? {
        get {
            switch self {
                case .resolved(let game): game.highlight
                case .stub(let game): game.highlight
            }
        }
        set {
            switch self {
                case .resolved(var game):
                    game.highlight = newValue
                    self = .resolved(game)
                case .stub(var game):
                    game.highlight = newValue
                    self = .stub(game)
            }
        }
    }

}

struct RecentlyOpenedSharedGame: Codable {

    let gameId: String
    let lastOpened: Date

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
    var highlight: SWHighlight?

    enum CodingKeys: CodingKey {
        case gameId
        case puzzle
    }

}
