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
import Reachability

protocol GameClientDelegate: AnyObject {
    func gameClient(_ client: GameClient, cursorsDidChange cursors: [String: Cursor])
    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]], isBulkUpdate: Bool, solutionState: GameClient.SolutionState)
    func gameClient(_ client: GameClient, didReceiveNewChatMessage message: ChatEvent, from: Player)
    func gameClient(_ client: GameClient, didReceivePing ping: PingEvent, from: Player)
    func gameClient(_ client: GameClient, connectionStateDidChange connectionState: GameClient.ConnectionState)
    func gameClient(_ client: GameClient, newPlayerJoined player: Player)
    func gameClient(_ client: GameClient, timeClockStateDidChange state: TimeClock.ClockState)
}

class GameClient: NSObject, URLSessionDelegate {
    
    enum SolutionState: Codable {
        case empty
        case incomplete
        case incorrect
        case correct

        var isFilledIn: Bool {
            return ![.empty, .incomplete].contains(self)
        }
    }

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
    
    enum InputMode: Int, Codable, CaseIterable, SettingsDisplayable {
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

    private(set) var puzzleId: String
    var defersJoining: Bool = false
    let reachability = try! Reachability()
    var solutionState: SolutionState = .empty
    lazy var inputMode: InputMode = self.settingsStorage.defaultInputMode
    var puzzle: Puzzle
    let userId: String
    let settingsStorage: SettingsStorage
    let correctSolution: [[String?]]
    var mostRecentDedupableEvents: [String: String] = [:]
    var timeClock: TimeClock = TimeClock()
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
                self.solutionState = self.resolveSolutionState()
                if self.solutionState == .correct {
                    self.timeClock.stop()
                }

                self.delegate?.gameClient(self, solutionDidChange: self.solution, isBulkUpdate: false, solutionState: self.solutionState)
            }
        }
    }
    
    var cursors: [String: Cursor] = [:] {
        didSet {
            self.delegate?.gameClient(self, cursorsDidChange: self.cursors)
        }
    }
    
    var playerActivityTimer: (playerSnapshot: Player, timer: Timer)?

    private let playersSubject: PassthroughSubject<[String: Player], Never> = PassthroughSubject()
    lazy var playersPublisher: AnyPublisher<[String: Player], Never> = self.playersSubject.eraseToAnyPublisher()
    private var needsToPublishPlayers: Bool = false
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

                if let playerActivityTimer,
                    playerActivityTimer.playerSnapshot.userId == playerId &&
                    playerActivityTimer.playerSnapshot.lastActivityTimeInterval < player.lastActivityTimeInterval {
                    playerActivityTimer.timer.invalidate()

                    // most inactive user performed an activity
                    self.playerActivityTimer = nil
                }
            }

            if self.playerActivityTimer == nil {
                self.setPlayerActivityTimer()
            }

            self.cursors = cursors

            if !self.isPerformingBulkEventSync {
                let oldPlayerIds = Set(oldValue.values)
                    .filter({ $0.isComplete })
                    .map(\.userId)
                let newPlayers = Set(players.values).filter({ $0.isComplete && !oldPlayerIds.contains($0.userId) })
                for newPlayer in newPlayers {
                    if newPlayer.userId != self.userId {
                        self.delegate?.gameClient(self, newPlayerJoined: newPlayer)
                    }
                }

                if self.players != oldValue || self.needsToPublishPlayers {
                    self.needsToPublishPlayers = false
                    self.playersSubject.send(self.players)
                }
            }
        }
    }

    func setPlayerActivityTimer() {
        let activePlayers = self.players.filter(\.value.isActive)
        guard let firstPlayer = activePlayers.first?.value as? Player else { return }

        let mostInactivePlayer = activePlayers.reduce(firstPlayer, { partialResult, element in
            if element.value.lastActivityTimeInterval < partialResult.lastActivityTimeInterval {
                return element.value
            } else {
                return partialResult
            }
        })

        if mostInactivePlayer.isActive {
            let timeout = Player.activityTimeoutInterval - (Date().timeIntervalSince1970 - mostInactivePlayer.lastActivityTimeInterval)
            self.playerActivityTimer = (mostInactivePlayer, Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] timer in
                guard let self else { return }
                self.needsToPublishPlayers = true
                self.players = self.players // publishes the players

                self.playerActivityTimer = nil
                self.setPlayerActivityTimer()
            }))
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
    
    init(puzzle: Puzzle, puzzleId: String, userId: String, gameId: String, settingsStorage: SettingsStorage) {
        self.puzzle = puzzle
        self.userId = userId
        self.gameId = gameId
        self.puzzleId = puzzleId
        self.settingsStorage = settingsStorage
        
        if let loadedSolution = Self.loadSolution(forGameId: self.gameId) {
            self.solution = loadedSolution
        } else {
            self.solution = Self.createEmptySolution(forPuzzle: puzzle)
        }
        
        self.correctSolution = self.puzzle.grid.map({ $0.map({ $0 == "." ? nil : $0 }) })
        
        super.init()
        self.timeClock.delegate = self
        self.solutionState = self.resolveSolutionState()

        do {
            self.reachability.whenReachable = { [weak self] _ in self?.reachabilityDidChange() }
            self.reachability.whenUnreachable = { [weak self] _ in self?.reachabilityDidChange() }
            try self.reachability.startNotifier()
        } catch {
            print("Couldn't start the reachability notifier")
        }
    }
    
    @objc func reachabilityDidChange() {
        self.socketManager.reconnect()
    }
    
    func connect() {
        self.connectionState = .connecting
        let socket = self.socketManager.defaultSocket

        socket.on("connect") { [weak self] data, ack in
            guard let self else { return }
            print("connected!")

            // start receiving events for this game
            self.emitWithAckNoOp(eventName: "join_game", self.gameId)
            
            // actually insert ourselves as a player
            if !self.defersJoining {
                self.joinGame()
            }

            self.performBulkSync()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            guard let self else { return }
            self.connectionState = .connecting
            print("GameClient<\(self.gameId)> disconnected")
        }
        
        socket.on(clientEvent: .reconnect) { [weak self] data, ack in
            guard let self else { return }
            self.connectionState = .connecting
        }
        
        socket.on(clientEvent: .reconnectAttempt) { [weak self] data, ack in
            guard let self else { return }
            self.connectionState = .connecting
        }
        
        socket.on("game_event") { [weak self] data, ack in
            guard let self, let events = data as? [[String: Any]] else { return }
            self.handleGameEvents(events, timeClock: self.timeClock)
        }
        
        socket.connect()
    }

    func disconnect() {
        self.socketManager.defaultSocket.disconnect()
    }

    func performBulkSync() {
        self.connectionState = .syncing

        self.emitWithAck("sync_all_game_events", self.gameId).timingOut(after: 5) { [weak self] data in
            guard let self, let events = data.first as? [[String: Any]] else { return }
            self.isPerformingBulkEventSync = true
            self.solution = Self.createEmptySolution(forPuzzle: self.puzzle)

            let timeClock = TimeClock()

            self.handleGameEvents(events, timeClock: timeClock)
            self.playersSubject.send(self.players)
            self.isPerformingBulkEventSync = false
            self.writeCurrentSolutionToFile()
            self.connectionState = .connected

            self.timeClock = timeClock
            timeClock.delegate = self

            self.delegate?.gameClient(self,
                                      solutionDidChange: self.solution,
                                      isBulkUpdate: true,
                                      solutionState: self.solutionState)

        }
    }

    func joinGame() {
        self.emitWithAckNoOp(UpdateDisplayNameEvent(userId: self.userId,
                                                    gameId: self.gameId,
                                                    displayName: self.settingsStorage.userDisplayName))
        self.emitWithAckNoOp(UpdateColorEvent(gameId: self.gameId,
                                              userId: self.userId,
                                              color: self.settingsStorage.userDisplayColor))
        self.players[self.userId] = Player(userId: self.userId,
                                           displayName: self.settingsStorage.userDisplayName,
                                           color: self.settingsStorage.userDisplayColor)
    }

    func handleGameEvents(_ data: [[String: Any]], timeClock: TimeClock) {
        for payload in data {
            guard let type = payload["type"] as? String else {
                print("Encountered invalid game event payload")
                return
            }

            timeClock.accountFor(rawEvent: payload)

            do {
                var genericEvent: GameEvent?
                var applyClosure: (() -> Void)
                if type == "updateCursor" {
                    guard self.solution.count > 0 else { continue }
                    let event = UpdateCursorEvent(payload: payload)
                    genericEvent = event
                    applyClosure = {
                        if var cursor = self.cursors[event.userId] {
                            cursor.coordinates = event.cell
                            self.cursors[event.userId] = cursor
                        } else {
                            self.cursors[event.userId] = Cursor(player: Player(userId: event.userId), coordinates: event.cell)
                        }
                    }
                } else if type == "updateCell"  {
                    guard self.solution.count > 0 &&
                          (self.solutionState != .correct || self.isPerformingBulkEventSync) else { continue }
                    let event = try UpdateCellEvent(payload: payload)
                    genericEvent = event
                    applyClosure = {
                        if let value = event.value, value != "" {
                            var correctness: Correctness?
                            if let autocheck = event.autocheck, autocheck {
                                correctness = self.correctness(forEntry: value, at: event.cell)
                            } else if let pencil = event.pencil, pencil {
                                correctness = .penciled
                            }

                            self.solution[event.cell.row][event.cell.cell] = CellEntry(userId: event.userId, value: value, correctness: correctness)
                        } else {
                            self.solution[event.cell.row][event.cell.cell] = nil
                        }
                    }
                } else if type == "updateColor" {
                    let event = try UpdateColorEvent(payload: payload)
                    genericEvent = event
                    applyClosure = {
                        var player = self.players[event.userId] ?? Player(userId: event.userId)
                        player.color = event.color
                        self.players[event.userId] = player
                    }
                } else if type == "check" {
                    let event = try CheckEvent(payload: payload)
                    genericEvent = event
                    guard self.solution.count > 0, !event.cells.isEmpty else { continue }
                    applyClosure = {
                        var intermediateSolution = self.solution
                        for cell in event.cells {
                            if let existingCorrectness = self.solution[cell]?.correctness,
                                existingCorrectness == .revealed {
                                continue
                            }

                            let correctness = self.correctness(forEntryAt: cell, in: intermediateSolution)
                            intermediateSolution[cell.row][cell.cell]?.correctness = correctness
                        }
                        self.solution = intermediateSolution
                    }
                } else if type == "reset" {
                    let event = try ResetEvent(payload: payload)
                    genericEvent = event
                    guard self.solution.count > 0, !event.cells.isEmpty else { continue }
                    applyClosure = {
                        var intermediateSolution = self.solution
                        for cell in event.cells {
                            intermediateSolution[cell.row][cell.cell] = nil
                        }
                        self.solution = intermediateSolution
                    }
                } else if type == "reveal" {
                    let event = try RevealEvent(payload: payload)
                    genericEvent = event
                    guard self.solution.count > 0, !event.cells.isEmpty else { continue }
                    applyClosure = {
                        var intermediateSolution = self.solution
                        for cell in event.cells {
                            let correctValue = self.puzzle.grid[cell.row][cell.cell]
                            if correctValue != ".", intermediateSolution[cell.row][cell.cell]?.correctness != .correct {
                                intermediateSolution[cell.row][cell.cell] = CellEntry(userId: "REVEALED",
                                                                                      value: correctValue,
                                                                                      correctness: .revealed)
                            }
                        }
                        self.solution = intermediateSolution
                    }
                } else if type == "updateDisplayName" {
                    let event = try UpdateDisplayNameEvent(payload: payload)
                    genericEvent = event
                    applyClosure = {
                        var player = self.players[event.userId] ?? Player(userId: event.userId)
                        player.displayName = event.displayName
                        self.players[event.userId] = player
                    }
                } else if type == "chat" {
                    let event = try ChatEvent(payload: payload)
                    genericEvent = event
                    applyClosure = {
                        if let player = self.players[event.senderId] {
                            self.delegate?.gameClient(self, didReceiveNewChatMessage: event, from: player)
                        } else {
                            print("Received a chat message from an unknown player")
                        }
                    }
                } else if type == "create" {
                    applyClosure = {
                        if self.puzzle.grid.count == 0 {
                            do {
                                let puzzleListEntry = try PuzzleListEntry(createEventPayload: payload)
                                self.puzzle = puzzleListEntry.content
                                self.puzzleId = puzzleListEntry.pid
                                self.solution = Self.createEmptySolution(forPuzzle: self.puzzle)
                            } catch {
                                fatalError("Need to handle wonkiness happening here")
                            }
                        }
                    }
                } else if type == "addPing" {
                    guard !self.isPerformingBulkEventSync else { continue }
                    let event = try PingEvent(payload: payload)
                    genericEvent = event
                    applyClosure = {
                        if let player = self.players[event.userId] {
                            self.delegate?.gameClient(self, didReceivePing: event, from: player)
                        } else {
                            print("Received a ping from an unknown player")
                        }
                    }
                } else if type == "sendChatMessage" {
                    // no-op
                    applyClosure = {}
                } else {
                    applyClosure = {}
                    print("unknown game_event type: \(type)")
                }

                if let userEvent = genericEvent as? UserEvent {
                    self.players[userEvent.userId]?.lastActivityTimeInterval = userEvent.timestamp
                }

                if let dedupableEvent = genericEvent as? DedupableGameEvent,
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

            self.solutionState = self.resolveSolutionState()
            if self.solutionState == .correct {
                timeClock.stop()
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
            } else if self.inputMode == .pencil {
                resolvedValue?.correctness = .penciled
            }
        } else {
            resolvedValue = nil
        }
        
        self.timeClock.accountForFakeEvent()
        self.solution[coordinates.row][coordinates.cell] = resolvedValue

        self.emitWithAckNoOp(UpdateCellEvent(userId: self.userId,
                                             gameId: self.gameId,
                                             cell: coordinates,
                                             value: value,
                                             color: self.inputMode == .pencil ? self.settingsStorage.userDisplayColor : nil,
                                             autocheck: self.inputMode == .autocheck,
                                             pencil: self.inputMode == .pencil))
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
    
    func correctness(forEntryAt at: CellCoordinates, in solution: [[CellEntry?]]) -> Correctness? {
        guard let playerEntry = solution[at.row][at.cell] else {
            return nil
        }
        return correctness(forEntry: playerEntry.value, at: at)
    }
    
    func correctness(forEntry entry: String, at: CellCoordinates) -> Correctness? {
        let correctValue = self.puzzle.grid[at.row][at.cell]
        return entry == correctValue ? .correct : .incorrect
    }
    
    func resolveSolutionState() -> SolutionState {
        var isFull = true
        var isEmpty = true

        if self.solution.cellCount != self.puzzle.grid.cellCount {
            return .incomplete
        }

        let proposedSolution: [[String?]] = self.solution.enumerated().map({ (rowIndex, row) in
            row.enumerated().map({ (cellIndex, cell) in
                if let cell {
                    if cell.value != "" {
                        isEmpty = false
                    }
                    return cell.value
                } else if isFull && ![".", ""].contains(self.puzzle.grid[rowIndex][cellIndex]) {
                    isFull = false
                }

                return nil
            })
        })

        var solutionState: SolutionState
        if proposedSolution == self.correctSolution {
            solutionState = .correct
        } else if isFull {
            solutionState = .incorrect
        } else if isEmpty {
            solutionState = .empty
        } else {
            solutionState = .incomplete
        }

        return solutionState
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
        guard puzzle.grid.count > 0 else {
            return []
        }

        return Array(repeating: Array(repeating: nil,
                                      count: puzzle.grid[0].count),
                     count: puzzle.grid.count)
    }
    
    func check(cells: [CellCoordinates]) {
        let event = CheckEvent(gameId: self.gameId, cells: cells)
        self.emitWithAckNoOp(event)
        self.handleGameEvents([event.eventPayload()], timeClock: self.timeClock)
    }
    
    func reveal(cells: [CellCoordinates]) {
        let event = RevealEvent(gameId: self.gameId, cells: cells)
        self.emitWithAckNoOp(event)
        self.handleGameEvents([event.eventPayload()], timeClock: self.timeClock)
    }

    func reset(cells: [CellCoordinates]) {
        let event = ResetEvent(gameId: self.gameId, cells: cells)
        self.emitWithAckNoOp(event)
        self.handleGameEvents([event.eventPayload()], timeClock: self.timeClock)
    }

    func ping(cell: CellCoordinates) {
        let event = PingEvent(userId: self.userId, gameId: self.gameId, cell: cell)
        self.emitWithAckNoOp(event)
        self.handleGameEvents([event.eventPayload()], timeClock: self.timeClock)
    }

}

extension GameClient: TimeClockDelegate {
    func timeClock(_ timeClock: TimeClock, stateDidChange state: TimeClock.ClockState) {
        self.delegate?.gameClient(self, timeClockStateDidChange: state)
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
