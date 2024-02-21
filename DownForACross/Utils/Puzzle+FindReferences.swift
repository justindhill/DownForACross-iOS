//
//  Puzzle+FindReferences.swift
//  DownForACross
//
//  Created by Justin Hill on 2/19/24.
//

import Foundation
import RegexBuilder

extension PuzzleClues {
    
    typealias ClueReference = (number: Int, direction: Direction)
    static func findReferences(clue: String) -> [ClueReference] {
        let numberFormatter = NumberFormatter()
        var references: [ClueReference] = []
        let cellNumber = Reference(Int.self)
        
        let clueReferenceRegex = Regex {
            TryCapture(as: cellNumber, { OneOrMore(.digit) }, transform: { match in
                return numberFormatter.number(from: String(match))?.intValue
            })
            "-"
            Optionally {
                Capture {
                    ChoiceOf {
                        "Down"
                        "Across"
                    }
                }
            }
            Optionally {
                ","
            }
            ChoiceOf {
                " "
                "."
            }
        }
        
        var mostRecentDirection: Direction = .down
        for match in clue.matches(of: clueReferenceRegex).reversed() {
            let (_, number, direction) = match.output
            var directionEnum: Direction
            if direction == "Down" {
                directionEnum = .down
            } else if direction == "Across" {
                directionEnum = .across
            } else {
                directionEnum = mostRecentDirection
            }
            mostRecentDirection = directionEnum
            
            references.append(ClueReference(number: number, direction: directionEnum))
        }
        
        return references
    }
    
}
