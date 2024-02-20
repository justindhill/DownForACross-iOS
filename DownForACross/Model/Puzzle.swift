//
//  Puzzle.swift
//  DownForACross
//
//  Created by Justin Hill on 12/18/23.
//

import Foundation

struct Puzzle: Codable, Hashable {
    var grid: [[String]]
    let info: PuzzleInfo

    let clues: PuzzleClues
    let shades: [Int]

    let circles: [Int]
    let `private`: Bool
}

struct PuzzleList: Codable, Hashable {
    let puzzles: [PuzzleListEntry]
}

struct PuzzleListEntry: Codable, Hashable, Identifiable {
    var id: String {
        return self.pid
    }
    
    let pid: String
    let content: Puzzle
    let stats: PuzzleStats
}

struct PuzzleStats: Codable, Hashable {
    let numSolves: Int
}

struct PuzzleInfo: Codable, Hashable {
    let type: String?
    let title: String
    let author: String
    let description: String
}

struct PuzzleClues: Codable, Hashable {
    let across: [String?]
    let down: [String?]
}
