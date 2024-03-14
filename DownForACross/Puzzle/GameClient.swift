//
//  GameClient.swift
//  DownForACross
//
//  Created by Justin Hill on 12/21/23.
//

import Foundation
import UIKit
import SocketIO
import Combine

protocol GameClientDelegate: AnyObject {
    func gameClient(_ client: GameClient, cursorsDidChange: [String: Cursor])
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]], isBulkUpdate: Bool, isSolved: Bool)
    func gameClient(_ client: GameClient, didReceiveNewChatMessage: ChatEvent, from: Player)
    func gameClient(_ client: GameClient, connectionStateDidChange: GameClient.ConnectionState)
}

class GameClient: NSObject, URLSessionDelegate {
    
    enum ConnectionState {
        case disconnected
        case connecting
        case syncing
        case connected
        
        var displayString: String {
            switch self {
                case .disconnected: "Disconnected"
                case .connecting: "Connecting"
                case .syncing: "Updating"
                case .connected: "Let's play!"
            }
        }
    }
    
    enum InputMode: Int, CaseIterable {
        case normal
        case autocheck
        case pencil
        
        var displayString: String {
            switch self {
                case .normal: "Normal"
                case .autocheck: "Auto-check"
                case .pencil: "Pencil"
            }
        }
    }
    
    weak var delegate: GameClientDelegate?
    
    var isPuzzleSolved: Bool = false
    var inputMode: InputMode = .normal
    let puzzle: Puzzle
    let userId: String
    let settingsStorage: SettingsStorage
    let correctSolution: [[String?]]
    var mostRecentDedupableEvents: [String: String] = [:]
    var connectionState: ConnectionState = .disconnected {
        didSet {
            self.delegate?.gameClient(self, connectionStateDidChange: connectionState)
        }
    }
    
    private(set) var isPerformingBulkEventSync: Bool = false
    private(set) var gameId: String
    
    private(set) var solution: [[CellEntry?]] {
        didSet {
            if !self.isPerformingBulkEventSync && oldValue != solution {
                self.writeCurrentSolutionToFile()
                self.delegate?.gameClient(self, solutionDidChange: self.solution, isBulkUpdate: false, isSolved: self.checkIfPuzzleIsSolved())
            }
        }
    }
    
    var cursors: [String: Cursor] = [:] {
        didSet {
            self.delegate?.gameClient(self, cursorsDidChange: self.cursors)
        }
    }
    
    @Published
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
        var components = Config.apiBaseURLComponents
        components.path = "/socket.io"
        var secure = true
        #if DFAC_LOCAL_SERVER
        components.scheme = "ws"
        secure = false
        #endif
        
        return SocketManager(
            socketURL: components.url!,
            config: [
                .version(.two),
                .forceWebsockets(true),
                .secure(secure)
            ]
        )
    }()
    
    init(puzzle: Puzzle, userId: String, gameId: String?, settingsStorage: SettingsStorage) {
        self.puzzle = puzzle
        self.userId = userId
        self.gameId = gameId ?? ""
        self.settingsStorage = settingsStorage
        
        if let loadedSolution = Self.loadSolution(forGameId: self.gameId) {
            self.solution = loadedSolution
        } else {
            self.solution = Self.createEmptySolution(forPuzzle: puzzle)
        }
        
        self.correctSolution = self.puzzle.grid.map({ $0.map({ $0 == "." ? nil : $0 }) })
        
        super.init()
        self.isPuzzleSolved = self.checkIfPuzzleIsSolved()
    }
    
    
    
    func connect(gameId: String? = nil) {
        self.connectionState = .connecting
        let socket = self.socketManager.defaultSocket
        
        let resolvedGameId = gameId ?? self.gameId
        guard resolvedGameId != "" else {
            fatalError("You must either pass a game id in the initializer or in connect!")
        }
        
        self.gameId = resolvedGameId
        
        socket.on("connect") { data, ack in
            self.connectionState = .syncing
            print("connected!")
            self.emitWithAckNoOp(eventName: "join_game", resolvedGameId)
            self.emitWithAckNoOp(UpdateDisplayNameEvent(userId: self.userId,
                                                        gameId: self.gameId,
                                                        displayName: self.settingsStorage.userDisplayName))
            self.emitWithAckNoOp(UpdateColorEvent(gameId: self.gameId,
                                                  userId: self.userId,
                                                  color: self.settingsStorage.userDisplayColor))
            self.players[self.userId] = Player(userId: self.userId,
                                               displayName: self.settingsStorage.userDisplayName,
                                               color: self.settingsStorage.userDisplayColor)
            
            self.emitWithAck("sync_all_game_events", self.gameId).timingOut(after: 5) { [weak self] data in
                guard let self, let events = data.first as? [[String: Any]] else { return }
                self.isPerformingBulkEventSync = true
                self.solution = Self.createEmptySolution(forPuzzle: self.puzzle)
                self.handleGameEvents(events)
                self.isPerformingBulkEventSync = false
                self.writeCurrentSolutionToFile()
                self.connectionState = .connected
                self.delegate?.gameClient(self,
                                          solutionDidChange: self.solution,
                                          isBulkUpdate: true, 
                                          isSolved: self.checkIfPuzzleIsSolved())
            }
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            self.connectionState = .connecting
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
                var dedupableEvent: DedupableGameEvent?
                var applyClosure: (() -> Void)
                if type == "updateCursor" {
                    let event = UpdateCursorEvent(payload: payload)
                    applyClosure = {
                        if var cursor = self.cursors[event.userId] {
                            cursor.coordinates = event.cell
                            self.cursors[event.userId] = cursor
                        } else {
                            self.cursors[event.userId] = Cursor(player: Player(userId: event.userId), coordinates: event.cell)
                        }
                    }
                } else if type == "updateCell"  {
                    let event = UpdateCellEvent(payload: payload)
                    dedupableEvent = event
                    applyClosure = {
                        if let value = event.value, value != "" {
                            var correctness: Correctness?
                            if let autocheck = event.autocheck, autocheck {
                                correctness = self.correctness(forEntry: value, at: event.cell)
                            }
                            
                            self.solution[event.cell.row][event.cell.cell] = CellEntry(userId: event.userId, value: value, correctness: correctness)
                        } else {
                            self.solution[event.cell.row][event.cell.cell] = nil
                        }
                    }
                } else if type == "updateColor" {
                    let event = try UpdateColorEvent(payload: payload)
                    dedupableEvent = event
                    applyClosure = {
                        var player = self.players[event.userId] ?? Player(userId: event.userId)
                        player.color = event.color
                        self.players[event.userId] = player
                    }
                } else if type == "check" {
                    let event = try CheckEvent(payload: payload)
                    applyClosure = {
                        for cell in event.cells {
                            let correctness = self.correctness(forEntryAt: cell)
                            self.solution[cell.row][cell.cell]?.correctness = correctness
                        }
                    }
                } else if type == "reveal" {
                    let event = try RevealEvent(payload: payload)
                    applyClosure = {
                        for cell in event.cells {
                            let correctValue = self.puzzle.grid[cell.row][cell.cell]
                            if correctValue != ".", self.solution[cell.row][cell.cell]?.correctness != .correct {
                                self.solution[cell.row][cell.cell] = CellEntry(userId: "REVEALED",
                                                                               value: correctValue,
                                                                               correctness: .revealed)
                            }
                        }
                    }
                } else if type == "updateDisplayName" {
                    let event = try UpdateDisplayNameEvent(payload: payload)
                    dedupableEvent = event
                    applyClosure = {
                        var player = self.players[event.userId] ?? Player(userId: event.userId)
                        player.displayName = event.displayName
                        self.players[event.userId] = player
                    }
                } else if type == "chat" {
                    let event = try ChatEvent(payload: payload)
                    applyClosure = {
                        if let player = self.players[event.senderId] {
                            self.delegate?.gameClient(self, didReceiveNewChatMessage: event, from: player)
                        } else {
                            print("Received a chat message from an unknown player")
                        }
                        print("CHAT: \(event.senderName) \(event.message)")
                    }
                } else if type == "sendChatMessage" {
                    // no-op
                    applyClosure = {}
                } else {
                    applyClosure = {}
                    print("unknown game_event type: \(type)")
                }
                
                if let dedupableEvent,
                    dedupableEvent.userId == self.userId {
                    
                    if let mostRecent = self.mostRecentDedupableEvents[dedupableEvent.dedupKey] {
                        // only apply if this is the most recent event we sent
                        if dedupableEvent.eventId == mostRecent {
                            applyClosure()
                        }
                    } else {
                        // we haven't sent an event of this type yet
                        applyClosure()
                    }
                } else {
                    // not a dedupable event or is one, but doesn't match our user id
                    applyClosure()
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
            if self.inputMode == .autocheck {
                let correctness: Correctness = self.puzzle.grid[coordinates.row][coordinates.cell] == value ? .correct : .incorrect
                resolvedValue?.correctness = correctness
            }
        } else {
            resolvedValue = nil
        }
        
        self.solution[coordinates.row][coordinates.cell] = resolvedValue

        
        self.emitWithAckNoOp(UpdateCellEvent(userId: self.userId,
                                             gameId: self.gameId,
                                             cell: coordinates,
                                             value: value,
                                             autocheck: self.inputMode == .autocheck))
    }
    
    func moveUserCursor(to coordinates: CellCoordinates) {
        self.emitWithAckNoOp(UpdateCursorEvent(userId: self.userId,
                                               gameId: self.gameId,
                                               coordinates: coordinates))
    }
    
    func sendMessage(_ message: String) -> ChatEvent {
        let event = ChatEvent(gameId: self.gameId,
                              senderId: self.userId,
                              senderName: self.settingsStorage.userDisplayName,
                              message: message)
        self.emitWithAckNoOp(event)
        return event
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
        let solved = proposedSolution == self.correctSolution
        self.isPuzzleSolved = solved
        
        return solved
    }
    
    func writeCurrentSolutionToFile() {
        guard self.gameId != "" else { return }
        
        let filePath = Self.createFilePath(forGameId: self.gameId)
        let jsonEncoder = JSONEncoder()
        guard let encodedSolution = try? jsonEncoder.encode(self.solution) else {
            print("Couldn't encode the solution")
            return
        }
        
        Self.createSolutionsPathIfNecessary()
        
        let success = FileManager.default.createFile(atPath: filePath, contents: encodedSolution, attributes: nil)
        if !success {
            print("Unable to write solution file for \(self.gameId)")
        }
    }
    
    static func loadSolution(forGameId gameId: String) -> [[CellEntry?]]? {
        guard gameId != "" else { return nil }

        let filePath = self.createFilePath(forGameId: gameId)
        let jsonDecoder = JSONDecoder()
        
        guard let data = FileManager.default.contents(atPath: filePath) else { return nil }
        guard let decodedSolution = try? jsonDecoder.decode([[CellEntry?]].self, from: data) else {
            print("Couldn't decode the solution")
            return nil
        }
        
        return decodedSolution
    }
    
    static func createSolutionsPathIfNecessary() {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath: String = (documentsDirectory as NSString).appendingPathComponent("solutions")
        var isDirectory: ObjCBool = false
        if !(FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) && isDirectory.boolValue) {
            var components = URLComponents(string: filePath)!
            components.scheme = "file"
            try? FileManager.default.createDirectory(at: components.url!, withIntermediateDirectories: true)
        }
    }
    
    static func createFilePath(forGameId gameId: String) -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        var filePath: String = (documentsDirectory as NSString).appendingPathComponent("solutions")
        filePath = (filePath as NSString).appendingPathComponent("\(gameId).json")
        
        return filePath
    }
    
    static func createEmptySolution(forPuzzle puzzle: Puzzle) -> [[CellEntry?]] {
        return Array(repeating: Array(repeating: nil,
                                      count: puzzle.grid[0].count),
                     count: puzzle.grid.count)
    }
    
    func check(cells: [CellCoordinates]) {
        let event = CheckEvent(gameId: self.gameId, cells: cells)
        self.emitWithAckNoOp(event)
        self.handleGameEvents([event.eventPayload()])
    }
    
    func reveal(cells: [CellCoordinates]) {
        let event = RevealEvent(gameId: self.gameId, cells: cells)
        self.emitWithAckNoOp(event)
        self.handleGameEvents([event.eventPayload()])
    }
    
}

extension GameClient {
    func emitWithAck(_ gameEvent: GameEvent) -> OnAckCallback {
        return self.socketManager.defaultSocket.emitWithAck("game_event", gameEvent.emitPayload())
    }
    
    func emitWithAckNoOp(_ gameEvent: GameEvent) {
        self.socketManager.defaultSocket.emitWithAck("game_event", gameEvent.emitPayload()).timingOut(after: 5, callback: { _ in })
    }
    
    func emitWithAck(_ gameEvent: DedupableGameEvent) -> OnAckCallback {
        self.mostRecentDedupableEvents[gameEvent.dedupKey] = gameEvent.eventId
        return self.socketManager.defaultSocket.emitWithAck("game_event", gameEvent.emitPayload())
    }
    
    func emitWithAckNoOp(_ gameEvent: DedupableGameEvent) {
        self.mostRecentDedupableEvents[gameEvent.dedupKey] = gameEvent.eventId
        self.socketManager.defaultSocket.emitWithAck("game_event", gameEvent.emitPayload()).timingOut(after: 5, callback: { _ in })
    }
    
    func emitWithAckNoOp(eventName: String = "game_event", _ items: SocketData...) {
        self.socketManager.defaultSocket.emitWithAck(eventName, items).timingOut(after: 5, callback: { _ in })
    }
    
    func emitWithAck(_ event: String, _ items: SocketData...) -> OnAckCallback {
        self.socketManager.defaultSocket.emitWithAck(event, with: items)
    }
}
