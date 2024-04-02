//
//  SharedGameInfoResolver.swift
//  DownForACross
//
//  Created by Justin Hill on 3/29/24.
//

import Foundation
import SharedWithYou

class SharedGameInfoResolver {

    enum Error: Swift.Error {
        case alreadyFetching
        case deallocated
    }

    let userId: String
    let settingsStorage: SettingsStorage
    var cachedGameInfo: [String: ResolvedSharedGame] {
        get {
            return self.settingsStorage.cachedSharedGameInfo
        }
        set {
            self.settingsStorage.cachedSharedGameInfo = newValue
        }
    }
    var completions: [String: (ResolvedSharedGame) -> Void] = [:]

    init(userId: String, settingsStorage: SettingsStorage) {
        self.userId = userId
        self.settingsStorage = settingsStorage
        self.cachedGameInfo = settingsStorage.cachedSharedGameInfo
    }

    @MainActor
    func gameInfo(gameId: String, highlight: SWHighlight?, resolutionCompletion: @escaping (Result<ResolvedSharedGame, NSError>) -> Void) -> SharedGame {
        if var cached = self.cachedGameInfo[gameId] {
            cached.highlight = highlight
            return .resolved(cached)
        }

        Task {
            if var gameInfo = try? await self.gameInfo(gameId: gameId) {
                gameInfo.highlight = highlight
                resolutionCompletion(.success(gameInfo))
            }
        }

        return .stub(StubSharedGame(gameId: gameId, highlight: highlight))
    }

    @MainActor
    private func gameInfo(gameId: String) async throws -> ResolvedSharedGame {
        if self.completions[gameId] != nil {
            throw Error.alreadyFetching
        }

        let gameClient = GameClient(puzzle: .empty(),
                                    puzzleId: "",
                                    userId: self.userId,
                                    gameId: gameId,
                                    settingsStorage: self.settingsStorage)
        gameClient.defersJoining = true
        gameClient.delegate = self
        gameClient.connect()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.completions[gameId] = { [weak self] sharedGame in
                    guard let self else {
                        continuation.resume(throwing: Error.deallocated)
                        return
                    }
                    self.cachedGameInfo[gameId] = sharedGame
                    continuation.resume(with: .success(sharedGame))
                }
            }
        }
    }

}

extension SharedGameInfoResolver: GameClientDelegate {

    func gameClient(_ client: GameClient, newPlayerJoined player: Player) {
        // no-op
    }

    func gameClient(_ client: GameClient, cursorsDidChange cursors: [String : Cursor]) {
        // no-op
    }

    func gameClient(_ client: GameClient, solutionDidChange solution: [[CellEntry?]], isBulkUpdate: Bool, isSolved: Bool) {
        // no-op
    }

    func gameClient(_ client: GameClient, didReceiveNewChatMessage message: ChatEvent, from: Player) {
        // no-op
    }

    func gameClient(_ client: GameClient, connectionStateDidChange connectionState: GameClient.ConnectionState) {
        switch connectionState {
            case .connecting, .disconnected, .syncing:
                break
            case .connected:
                if let completion = self.completions[client.gameId] {
                    let gameInfo = ResolvedSharedGame(gameId: client.gameId, puzzle: client.puzzle)
                    completion(gameInfo)
                    self.completions[client.gameId] = nil
                    client.disconnect()
                }
        }
    }

}
