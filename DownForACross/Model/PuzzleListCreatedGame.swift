//
//  PuzzleListCreatedGame.swift
//  DownForACross
//
//  Created by Justin Hill on 4/12/24.
//

import Foundation


struct PuzzleListCreatedGame: Codable {

    enum Completion: Codable {
        case incomplete
        case complete
        case completeAndCorrect
    }

    let gameId: String
    let completion: Completion

}
