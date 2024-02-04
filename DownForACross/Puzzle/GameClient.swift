//
//  GameClient.swift
//  DownForACross
//
//  Created by Justin Hill on 12/21/23.
//

import Foundation
import UIKit
import SocketIO

protocol GameClientDelegate: AnyObject {
    func gameClient(_ client: GameClient, cursorsDidChange: [String: Cursor])
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]], isSolved: Bool)
    func gameClient(_ client: GameClient, didReceiveNewChatMessage: ChatEvent, from: Player)
}

class GameClient: NSObject, URLSessionDelegate {
    
    weak var delegate: GameClientDelegate?
    
    var autocheckEnabled: Bool = true
    let puzzle: Puzzle
    let userId: String
    let correctSolution: [[String?]]
    private(set) var gameId: String = ""
    
    private(set) var solution: [[CellEntry?]] {
        didSet {
            if oldValue != solution {
                self.delegate?.gameClient(self, solutionDidChange: self.solution, isSolved: self.checkIfPuzzleIsSolved())
            }
        }
    }
    
    var cursors: [String: Cursor] = [:] {
        didSet {
            self.delegate?.gameClient(self, cursorsDidChange: self.cursors)
        }
    }
    
    var players: [String: Player] = [:] {
        didSet {
            var cursors = self.cursors
            players.forEach { (playerId, player) in
                if var cursor = cursors[playerId] {
                    cursor.player = player
                    cursors[playerId] = cursor
                } else {
                    cursors[playerId] = Cursor(player: player, coordinates: CellCoordinates(row: 0, cell: 0))
                }
            }
            
            self.cursors = cursors
        }
    }

    
    lazy var socketManager: SocketManager = {
//        SocketManager(socketURL: URL(string: "https://api.foracross.com/socket.io")!,
        SocketManager(socketURL: URL(string: "ws://localhost:3021/socket.io")!,
                      config: [
                        .version(.two),
                        .forceWebsockets(true)
//                        .secure(true)
                      ])
    }()
    
    init(puzzle: Puzzle, userId: String) {
        self.puzzle = puzzle
        self.userId = userId
        self.solution = Array(repeating: Array(repeating: nil,
                                               count: puzzle.grid[0].count),
                              count: puzzle.grid.count)
        
        self.correctSolution = self.puzzle.grid.map({ $0.map({ $0 == "." ? nil : $0 }) })
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
                    if var cursor = self.cursors[event.userId] {
                        cursor.coordinates = event.cell
                        self.cursors[event.userId] = cursor
                    } else {
                        self.cursors[event.userId] = Cursor(player: Player(), coordinates: event.cell)
                    }
                } else if type == "updateCell"  {
                    let event = UpdateCellEvent(payload: payload)
                    if let value = event.value, value != "" {
                        var correctness: Correctness?
                        if let autocheck = event.autocheck, autocheck {
                            correctness = self.correctness(forEntry: value, at: event.cell)
                        }
                        
                        self.solution[event.cell.row][event.cell.cell] = CellEntry(userId: event.userId, value: value, correctness: correctness)
                    } else {
                        self.solution[event.cell.row][event.cell.cell] = nil
                    }
                } else if type == "updateColor" {
                    let event = try UpdateColorEvent(payload: payload)
                    var player = self.players[event.userId] ?? Player()
                    player.color = event.color
                    self.players[event.userId] = player
                } else if type == "check" {
                    let event = try CheckEvent(payload: payload)
                    for cell in event.cells {
                        let correctness = self.correctness(forEntryAt: cell)
                        self.solution[cell.row][cell.cell]?.correctness = correctness
                    }
                } else if type == "updateDisplayName" {
                    let event = try UpdateDisplayNameEvent(payload: payload)
                    var player = self.players[event.userId] ?? Player()
                    player.displayName = event.displayName
                    self.players[event.userId] = player
                } else if type == "chat" {
                    let event = try ChatEvent(payload: payload)
                    if let player = self.players[event.senderId] {
                        self.delegate?.gameClient(self, didReceiveNewChatMessage: event, from: player)
                    } else {
                        print("Received a chat message from an unknown player")
                    }
                    print("CHAT: \(event.senderName) \(event.message)")
                } else if type == "sendChatMessage" {
                    // no-op
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
        var resolvedValue: CellEntry?
        if let value {
            resolvedValue = CellEntry(userId: self.userId, value: value, correctness: nil)
            if self.autocheckEnabled {
                let correctness: Correctness = self.puzzle.grid[coordinates.row][coordinates.cell] == value ? .correct : .incorrect
                resolvedValue?.correctness = correctness
            }
        } else {
            resolvedValue = nil
        }
        
        self.solution[coordinates.row][coordinates.cell] = resolvedValue

        
        self.socketManager.defaultSocket.emitWithAckNoOp(UpdateCellEvent(userId: self.userId,
                                                                         gameId: self.gameId,
                                                                         cell: coordinates,
                                                                         value: value,
                                                                         autocheck: self.autocheckEnabled).eventPayload())
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
        return correctness(forEntry: playerEntry.value, at: at)
    }
    
    func correctness(forEntry entry: String, at: CellCoordinates) -> Correctness? {
        let correctValue = self.puzzle.grid[at.row][at.cell]
        return entry == correctValue ? .correct : .incorrect
    }
    
    func checkIfPuzzleIsSolved() -> Bool {
        let proposedSolution = self.solution.map({ $0.map({ $0 == nil ? nil : $0!.value }) })
        return proposedSolution == self.correctSolution
    }
    
}
