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

    static func empty() -> Puzzle {
        return Puzzle(grid: [],
                      info: PuzzleInfo(type: nil, title: "", author: "", description: ""),
                      clues: PuzzleClues(across: [], down: []),
                      shades: [],
                      circles: [])
    }

    init(grid: [[String]], info: PuzzleInfo, clues: PuzzleClues, shades: [Int], circles: [Int]) {
        self.grid = grid
        self.info = info
        self.clues = clues
        self.shades = shades
        self.circles = circles
    }

    init(createEventPayload: [String: Any]) throws {
        guard let grid = createEventPayload["solution"] as? [[String]],
              let circles = createEventPayload["circles"] as? [Int],
              let cluesPayload = createEventPayload["clues"] as? [String: [String?]],
              let acrossClues = cluesPayload["across"],
              let downClues = cluesPayload["down"],
              let infoPayload = createEventPayload["info"] as? [String: String] else {
            throw NSError(domain: "PuzzleParsingDomain", code: 0)
        }

        self.grid = grid
        self.info = try PuzzleInfo(createEventPayload: infoPayload)
        self.clues = PuzzleClues(across: acrossClues, down: downClues)
        self.shades = []
        self.circles = circles
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

    init(pid: String, content: Puzzle, stats: PuzzleStats) {
        self.pid = pid
        self.content = content
        self.stats = stats
    }

    init(createEventPayload: [String: Any]) throws {
        guard let params = createEventPayload["params"] as? [String: Any],
              let game = params["game"] as? [String: Any],
              let pid = params["pid"] as? Int else {
            throw NSError(domain: "PuzzleParsingDomain", code: 0)
        }

        self.content = try Puzzle(createEventPayload: game)
        self.pid = String(pid)
        self.stats = PuzzleStats(numSolves: 0)
    }
}

struct PuzzleStats: Codable, Hashable {
    let numSolves: Int
}

struct PuzzleInfo: Codable, Hashable {
    let type: String?
    let title: String
    let author: String
    let description: String

    init(type: String?, title: String, author: String, description: String) {
        self.type = type
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        self.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(createEventPayload: [String: String]) throws {
        guard let title = createEventPayload["title"],
              let author = createEventPayload["author"],
              let description = createEventPayload["description"] else {
            throw NSError(domain: "PuzzleInfoParsingDomain", code: 0)
        }

        self.type = createEventPayload["type"]
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        self.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.title = try container.decode(String.self, forKey: .title).trimmingCharacters(in: .whitespacesAndNewlines)
        self.author = try container.decode(String.self, forKey: .author).trimmingCharacters(in: .whitespacesAndNewlines)
        self.description = try container.decode(String.self, forKey: .description).trimmingCharacters(in: .whitespacesAndNewlines)
    }
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
                throw NSError(domain: "PuzzleCluesParsingDomain", code: 0)
            }
            
            var list: [String?] = Array(repeating: nil, count: maxClueNumber + 1)
            for (key, value) in acrossDict {
                guard let index = Int(key) else { throw NSError(domain: "PuzzleCluesParsingDomain", code: 1) }
                list[index] = value
            }
            self.across = list
        } else {
            throw NSError(domain: "PuzzleCluesParsingDomain", code: 2)
        }
        
        if let downList = try? container.decode([String?].self, forKey: .down) {
            self.down = downList
        } else if let downDict = try? container.decode([String: String].self, forKey: .down) {
            guard let maxClueNumber = downDict.keys.compactMap({ Int($0) }).sorted().last else {
                throw NSError(domain: "PuzzleCluesParsingDomain", code: 3)
            }
            
            var list: [String?] = Array(repeating: nil, count: maxClueNumber + 1)
            for (key, value) in downDict {
                guard let index = Int(key) else { throw NSError(domain: "PuzzleCluesParsingDomain", code: 4) }
                list[index] = value
            }
            self.down = list
        } else {
            throw NSError(domain: "PuzzleCluesParsingDomain", code: 5)
        }
    }
}
