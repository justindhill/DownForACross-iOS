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
    
    let baseURLComponents = URLComponents(string: "https://api.foracross.com")!
    let session = URLSession.shared
    
    func getPuzzleList(page: Int = 0) async throws -> PuzzleList {
        var urlComponents = self.baseURLComponents
        urlComponents.path = "/api/puzzle_list"
        urlComponents.queryItems = []
        urlComponents.queryItems?.append(URLQueryItem(name: "page", value: "\(page)"))
        urlComponents.queryItems?.append(URLQueryItem(name: "pageSize", value: "50"))
        urlComponents.queryItems?.append(URLQueryItem(name: "filter[nameOrTitleFilter]", value: "LA times"))
        urlComponents.queryItems?.append(URLQueryItem(name: "filter[sizeFilter][Mini]", value: "true"))
        urlComponents.queryItems?.append(URLQueryItem(name: "filter[sizeFilter][Standard]", value: "true"))
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "API", code: 1)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5
        let (data, _) = try await session.data(for: request)
        
        let decoded = try jsonDecoder.decode(PuzzleList.self, from: data)
        return decoded
    }
    
}
