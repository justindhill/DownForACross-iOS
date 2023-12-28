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
    let gameId: String = "4374382-nund"
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
    
    
    
    func connect() {
        let socket = self.socketManager.defaultSocket
        
        socket.on("connect") { data, ack in
            print("connected!")
            socket.emit("join_game", "4374382-nund")
            socket.emit("game_event", UpdateDisplayNameEvent(userId: self.userId, 
                                                             gameId: self.gameId,
                                                             displayName: "It me, Justin").eventPayload())
            socket.emit("sync_all_game_events", self.gameId)
        }
        
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print(data)
        }
        
        socket.on("game_event") { data, ack in
            guard let payload = data.first as? [String: Any],
                  let type = payload["type"] as? String else {
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
            } else {
                print("unknown game_event type: \(type)")
            }
        }
        
        socket.connect()
    }
    
    func enter(value: String?, atCoordinates coordinates: CellCoordinates) {
        let resolvedValue: CellEntry?
        if let value {
            resolvedValue = CellEntry(userId: self.userId, value: value)
        } else {
            resolvedValue = nil
        }
        
        self.solution[coordinates.row][coordinates.cell] = resolvedValue
        self.socketManager.defaultSocket.emit(
            "game_event",
            UpdateCellEvent(userId: self.userId, 
                            gameId: self.gameId,
                            cell: coordinates,
                            value: value).eventPayload())
    }
    
    func moveUserCursor(to coordinates: CellCoordinates) {
        self.socketManager.defaultSocket.emit(
            "game_event",
            UpdateCursorEvent(userId: self.userId, 
                              gameId: self.gameId,
                              coordinates: coordinates).eventPayload())
    }
    
}
