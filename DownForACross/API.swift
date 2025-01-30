//
//  API.swift
//  DownForACross
//

import Foundation

class API {
    
    let jsonDecoder = JSONDecoder()
    
    enum APIError: Error {
        case invalidUrl
    }
    
    let baseURLComponents = Config.apiBaseURLComponents
    let session = URLSession.shared
    
    func getPuzzleList(page: Int = 0, wordFilter: String?, includeMinis: Bool, includeStandards: Bool, limit: Int = 50) async throws -> PuzzleList {
        var urlComponents = self.baseURLComponents
        urlComponents.path = "/api/puzzle_list"
        urlComponents.queryItems = []
        urlComponents.queryItems?.append(URLQueryItem(name: "page", value: "\(page)"))
        urlComponents.queryItems?.append(URLQueryItem(name: "pageSize", value: "\(limit)"))
        urlComponents.queryItems?.append(URLQueryItem(name: "filter[nameOrTitleFilter]", value: wordFilter))
        urlComponents.queryItems?.append(URLQueryItem(name: "filter[sizeFilter][Mini]", value: String(includeMinis)))
        urlComponents.queryItems?.append(URLQueryItem(name: "filter[sizeFilter][Standard]", value: String(includeStandards)))
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "API", code: 1)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let (data, _) = try await session.data(for: request)
        
        let decoded = try jsonDecoder.decode(PuzzleList.self, from: data)
        return decoded
    }
    
    func findPuzzle(name: String, id: String) async throws -> PuzzleListEntry? {
        let puzzleList = try await self.getPuzzleList(wordFilter: name, includeMinis: true, includeStandards: true, limit: 5)
        for puzzle in puzzleList.puzzles {
            if puzzle.pid == id {
                return puzzle
            }
        }
        
        return nil
    }

    func recordSolve(puzzleId: String, gameId: String, timeToSolve: TimeInterval) async throws -> Void {
        var urlComponents = self.baseURLComponents
        urlComponents.path = "/api/record_solve/\(puzzleId)"

        let params: [String: AnyHashable] = [
            "gid": gameId,
            "time_to_solve": Int(timeToSolve * 1000)
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        _ = try await self.session.data(for: request)
    }

}
