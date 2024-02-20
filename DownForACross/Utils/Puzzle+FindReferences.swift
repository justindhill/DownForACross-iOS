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
            Capture {
                ChoiceOf {
                    "Down"
                    "Across"
                }
            }
        }
        
        for match in clue.matches(of: clueReferenceRegex) {
            let (_, number, direction) = match.output
            var directionEnum: Direction
            if direction == "Down" {
                directionEnum = .down
            } else {
                directionEnum = .across
            }
            
            references.append(ClueReference(number: number, direction: directionEnum))
        }
        
        return references
    }
    
}
