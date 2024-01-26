//
//  GameClient.swift
//  DownForACross
//
//  Created by Justin Hill on 12/21/23.
//

import Foundation
import SocketIO

protocol GameClientDelegate: AnyObject {
    func gameClient(_ client: GameClient, cursorsDidChange: [String: CellCoordinates], colors: [String: UIColor])
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]])
}

class GameClient: NSObject, URLSessionDelegate {
    
    weak var delegate: GameClientDelegate?
    
    var autocheckEnabled: Bool = true
    let puzzle: Puzzle
    let userId: String
    private(set) var gameId: String = "" {
        didSet {
            print()
        }
    }
    private(set) var solution: [[CellEntry?]] {
        didSet {
            self.delegate?.gameClient(self, solutionDidChange: self.solution)
        }
    }
    
    var cursors: [String: CellCoordinates] = [:] {
        didSet {
            self.delegate?.gameClient(self, cursorsDidChange: self.cursors, colors: self.cursorColors)
        }
    }
    
    var cursorColors: [String: UIColor] = [:] {
        didSet {
            self.delegate?.gameClient(self, cursorsDidChange: self.cursors, colors: self.cursorColors)
        }
    }
    
    lazy var socketManager: SocketManager = {
        SocketManager(socketURL: URL(string: "https://api.foracross.com/socket.io")!,
                      config: [
                        .version(.two),
                        .forceWebsockets(true), 
                        .secure(true)])
    }()
    
    init(puzzle: Puzzle, userId: String) {
        self.puzzle = puzzle
        self.userId = userId
        self.solution = Array(repeating: Array(repeating: nil,
                                               count: puzzle.grid[0].count),
                              count: puzzle.grid.count)
    }
    
    
    
    func connect(gameId: String) {
        let socket = self.socketManager.defaultSocket
        self.gameId = gameId
        
        socket.on("connect") { data, ack in
            print("connected!")
            socket.emitWithAckNoOp(eventName: "join_game", gameId)
            socket.emitWithAckNoOp(UpdateDisplayNameEvent(userId: self.userId,
                                                          gameId: self.gameId,
                                                          displayName: "It me, Justin").eventPayload())
            
            socket.emitWithAck("sync_all_game_events", self.gameId).timingOut(after: 5) { data in
                guard let events = data.first as? [[String: Any]] else { return }
                self.handleGameEvents(events)
            }
        }
        
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print(data)
        }
        
        socket.on("game_event") { data, ack in
            guard let events = data as? [[String: Any]] else { return }
            self.handleGameEvents(events)
        }
        
        socket.connect()
    }
    
    func handleGameEvents(_ data: [[String: Any]]) {
        for payload in data {
            guard let type = payload["type"] as? String else {
                print("Encountered invalid game event payload")
                return
            }
            
            do {
                if type == "updateCursor" {
                    let event = UpdateCursorEvent(payload: payload)
                    self.cursors[event.userId] = event.cell
                } else if type == "updateCell" {
                    let event = UpdateCellEvent(payload: payload)
                    if let value = event.value, value != "" {
                        var correctness: Correctness?
                        if let playerEntry = self.solution[event.cell.row][event.cell.cell] {
                            if case .correct = playerEntry.correctness {
                                return
                            }
                            correctness = playerEntry.correctness
                        }
                        
                        self.solution[event.cell.row][event.cell.cell] = CellEntry(userId: event.userId, value: value, correctness: correctness)
                    } else {
                        self.solution[event.cell.row][event.cell.cell] = nil
                    }
                } else if type == "updateColor" {
                    let event = try UpdateColorEvent(payload: payload)
                    self.cursorColors[event.userId] = event.color
                } else if type == "check" {
                    let event = try CheckEvent(payload: payload)
                    for cell in event.cells {
                        let correctness = self.correctness(forEntryAt: cell)
                        self.solution[cell.row][cell.cell]?.correctness = correctness
                    }
                } else {
                    print("unknown game_event type: \(type)")
                }
            } catch {
                print("Encountered an error while parsing \"\(type)\" event")
                print(error)
            }
        }
    }
    
    func enter(value: String?, atCoordinates coordinates: CellCoordinates) {
        let resolvedValue: CellEntry?
        if let value {
            resolvedValue = CellEntry(userId: self.userId, value: value, correctness: nil)
        } else {
            resolvedValue = nil
        }
        
        self.solution[coordinates.row][coordinates.cell] = resolvedValue
        if self.autocheckEnabled {
            let correctness = self.correctness(forEntryAt: coordinates)
            self.solution[coordinates.row][coordinates.cell]?.correctness = correctness
        }
        
        self.socketManager.defaultSocket.emitWithAckNoOp(
            UpdateCellEvent(userId: self.userId,
                            gameId: self.gameId,
                            cell: coordinates,
                            value: value).eventPayload())
        
        if self.autocheckEnabled {
            self.socketManager.defaultSocket.emitWithAckNoOp(
                CheckEvent(gameId: self.gameId,
                           cells: [coordinates]).eventPayload())
        }
    }
    
    func moveUserCursor(to coordinates: CellCoordinates) {
        self.socketManager.defaultSocket.emitWithAckNoOp(
            UpdateCursorEvent(userId: self.userId,
                              gameId: self.gameId,
                              coordinates: coordinates).eventPayload())
    }
    
    func correctness(forEntryAt at: CellCoordinates) -> Correctness? {
        guard let playerEntry = self.solution[at.row][at.cell] else {
            return nil
        }
        let correctValue = self.puzzle.grid[at.row][at.cell]
        return playerEntry.value == correctValue ? .correct : .incorrect
    }
    
}
