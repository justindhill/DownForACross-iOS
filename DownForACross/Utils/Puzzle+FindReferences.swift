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
            ChoiceOf {
                "-"
                Local {
                    " "
                    Capture {
                        ChoiceOf {
                            "Down"
                            "Across"
                        }
                    }
                }
            }
            Optionally {
                Optionally {
                    " "
                }
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
        }
        
        var mostRecentDirection: Direction = .down
        for match in clue.matches(of: clueReferenceRegex).reversed() {
            let (_, number, direction1, direction2) = match.output
            var directionEnum: Direction
            if direction1 == "Down" || direction2 == "Down" {
                directionEnum = .down
            } else if direction1 == "Across" || direction2 == "Across" {
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
