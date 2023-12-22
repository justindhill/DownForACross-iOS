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
    
    init(puzzle: Puzzle) {
        self.puzzleInfo = puzzle.info
        self.solution = Array(repeating: Array(repeating: nil,
                                               count: puzzle.grid[0].count),
                              count: puzzle.grid.count)
    }
    
    
    
    func connect() {
        let socket = self.socketManager.defaultSocket
        
        socket.on("connect") { data, ack in
            print("connected!")
//            socket.emit("join_game", "4374382-nund")
            socket.emit("join_game", "4374382-nund")
            socket.emit("sync_all_game_events", "4374382-nund")
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
                self.cursors[event.id] = event.cell
            } else if type == "updateCell" {
                let event = UpdateCellEvent(payload: payload)
                self.solution[event.cell.row][event.cell.cell] = CellEntry(userId: event.id, value: event.value)
            } else {
                print("unknown game_event type: \(type)")
            }
        }
        
        socket.connect()
    }
    
}
