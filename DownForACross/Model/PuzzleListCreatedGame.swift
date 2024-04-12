//
//  PuzzleListCreatedGame.swift
//  DownForACross
//
//  Created by Justin Hill on 4/12/24.
//

import Foundation


struct PuzzleListCreatedGame: Codable {

    let gameId: String
    var completion: GameClient.SolutionState

}
