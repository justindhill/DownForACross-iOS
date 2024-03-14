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
    
    static func empty() -> Puzzle {
        return Puzzle(grid: [],
                      info: PuzzleInfo(type: nil, title: "", author: "", description: ""),
                      clues: PuzzleClues(across: [], down: []),
                      shades: [],
                      circles: [],
                      private: false)
    }
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
    
    init(across: [String?], down: [String?]) {
        self.across = across
        self.down = down
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let acrossList = try? container.decode([String?].self, forKey: .across) {
            self.across = acrossList
        } else if let acrossDict = try? container.decode([String: String].self, forKey: .across) {
            guard let maxClueNumber = acrossDict.keys.compactMap({ Int($0) }).sorted().last else {
                throw NSError(domain: "PuzzleParsingDomain", code: 0)
            }
            
            var list: [String?] = Array(repeating: nil, count: maxClueNumber + 1)
            for (key, value) in acrossDict {
                guard let index = Int(key) else { throw NSError(domain: "PuzzleParsingDomain", code: 1) }
                list[index] = value
            }
            self.across = list
        } else {
            throw NSError(domain: "PuzzleParsingDomain", code: 2)
        }
        
        if let downList = try? container.decode([String?].self, forKey: .down) {
            self.down = downList
        } else if let downDict = try? container.decode([String: String].self, forKey: .down) {
            guard let maxClueNumber = downDict.keys.compactMap({ Int($0) }).sorted().last else {
                throw NSError(domain: "PuzzleParsingDomain", code: 3)
            }
            
            var list: [String?] = Array(repeating: nil, count: maxClueNumber + 1)
            for (key, value) in downDict {
                guard let index = Int(key) else { throw NSError(domain: "PuzzleParsingDomain", code: 4) }
                list[index] = value
            }
            self.down = list
        } else {
            throw NSError(domain: "PuzzleParsingDomain", code: 5)
        }
    }
}
