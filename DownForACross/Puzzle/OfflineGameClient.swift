//
//  OfflineGameClient.swift
//  DownForACross
//
//  Created by Justin Hill on 10/24/24.
//

import SocketIO

class OfflineGameClient: GameClient {

    static let offlineGameId: String = "OFFLINE"

    init(puzzle: Puzzle, puzzleId: String, userId: String, settingsStorage: SettingsStorage) {
        super.init(puzzle: puzzle, puzzleId: puzzleId, userId: userId, gameId: Self.offlineGameId, settingsStorage: settingsStorage)
        self.connectionState = .connected

        if let savedState = Self.loadState(forPuzzleId: puzzleId) {
            self.solution = savedState.solution
        }
    }

    private static func createSolutionsPathIfNecessary() {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath: String = (documentsDirectory as NSString).appendingPathComponent("offlineSolutions")
        var isDirectory: ObjCBool = false
        if !(FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) && isDirectory.boolValue) {
            var components = URLComponents(string: filePath)!
            components.scheme = "file"
            try? FileManager.default.createDirectory(at: components.url!, withIntermediateDirectories: true)
        }
    }

    private static func createFilePath(forPuzzleId puzzleId: String) -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        var filePath: String = (documentsDirectory as NSString).appendingPathComponent("offlineSolutions")
        filePath = (filePath as NSString).appendingPathComponent("\(puzzleId).json")

        return filePath
    }

    private static func loadState(forPuzzleId puzzleId: String) -> SaveState? {
        guard puzzleId != "" else { return nil }

        let filePath = self.createFilePath(forPuzzleId: puzzleId)
        let jsonDecoder = JSONDecoder()

        guard let data = FileManager.default.contents(atPath: filePath) else { return nil }

        if let decodedSolution = try? jsonDecoder.decode(SaveState.self, from: data) {
            return decodedSolution
        } else if let decodedSolution = try? jsonDecoder.decode([[CellEntry?]].self, from: data) {
            return SaveState(solution: decodedSolution, lastReadMessageTimestamp: 0)
        } else {
            print("Couldn't decode the solution")
            return nil
        }
    }

    override func writeCurrentStateToFile() {
        let filePath = Self.createFilePath(forPuzzleId: self.puzzleId)
        let jsonEncoder = JSONEncoder()

        let saveState = SaveState(solution: self.solution,
                                  lastReadMessageTimestamp: self.lastReadMessageTimestamp)

        guard let encodedSaveState = try? jsonEncoder.encode(saveState) else {
            print("Couldn't encode the solution")
            return
        }

        Self.createSolutionsPathIfNecessary()

        let success = FileManager.default.createFile(atPath: filePath, contents: encodedSaveState, attributes: nil)
        if !success {
            print("Unable to write solution file for \(self.gameId)")
        }
    }

    override func connect() {}

    override func joinGame() {}

    override func performBulkSync() {}

    override func setupBackgroundBehavior() {}

    override func emitWithAck(_ gameEvent: GameEvent) -> OnAckCallback? {
        // no-op
        return nil
    }

    override func emitWithAckNoOp(_ gameEvent: GameEvent) {
        // no-op
    }

    override func emitWithAck(_ gameEvent: DedupableGameEvent) -> OnAckCallback? {
        // no-op
        return nil
    }

    override func emitWithAckNoOp(_ gameEvent: DedupableGameEvent) {
        // no-op
    }

    override func emitWithAckNoOp(eventName: String = "game_event", _ items: SocketData...) {
        // no-op
    }

    override func emitWithAck(_ event: String, _ items: SocketData...) -> OnAckCallback? {
        // no-op
        return nil
    }

}
