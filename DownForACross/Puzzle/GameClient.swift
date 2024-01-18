//
//  GameClient.swift
//  DownForACross
//
//  Created by Justin Hill on 12/21/23.
//

import Foundation
import SocketIO

protocol GameClientDelegate: AnyObject {
    func gameClient(_ client: GameClient, cursorsDidChange: [String: CellCoordinates])
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]])
}

class GameClient: NSObject, URLSessionDelegate {
    
    weak var delegate: GameClientDelegate?
    
    let puzzleInfo: PuzzleInfo
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
            self.delegate?.gameClient(self, cursorsDidChange: self.cursors)
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
        self.puzzleInfo = puzzle.info
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
            socket.emitWithAckNoOp("join_game", gameId)
            socket.emitWithAckNoOp("game_event", UpdateDisplayNameEvent(userId: self.userId,
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
            
            if type == "updateCursor" {
                let event = UpdateCursorEvent(payload: payload)
                self.cursors[event.userId] = event.cell
            } else if type == "updateCell" {
                let event = UpdateCellEvent(payload: payload)
                if let value = event.value {
                    self.solution[event.cell.row][event.cell.cell] = CellEntry(userId: event.userId, value: value)
                } else {
                    self.solution[event.cell.row][event.cell.cell] = nil
                }
            } else if type == "updateColor" {
                let event = UpdateColorEvent(payload: payload)
            } else {
                print("unknown game_event type: \(type)")
            }
        }
    }
    
    func enter(value: String?, atCoordinates coordinates: CellCoordinates) {
        let resolvedValue: CellEntry?
        if let value {
            resolvedValue = CellEntry(userId: self.userId, value: value)
        } else {
            resolvedValue = nil
        }
        
        self.solution[coordinates.row][coordinates.cell] = resolvedValue
        self.socketManager.defaultSocket.emitWithAckNoOp(
            "game_event",
            UpdateCellEvent(userId: self.userId, 
                            gameId: self.gameId,
                            cell: coordinates,
                            value: value).eventPayload())
    }
    
    func moveUserCursor(to coordinates: CellCoordinates) {
        self.socketManager.defaultSocket.emitWithAckNoOp(
            "game_event",
            UpdateCursorEvent(userId: self.userId, 
                              gameId: self.gameId,
                              coordinates: coordinates).eventPayload())
    }
    
}
