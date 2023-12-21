//
//  GameClient.swift
//  DownForACross
//
//  Created by Justin Hill on 12/21/23.
//

import Foundation

class GameClient: NSObject, URLSessionDelegate {
    
    var pingTimer: Timer?
    
    lazy var urlSession: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        return session
    }()
    
    lazy var task = URLSession.shared.webSocketTask(
        with: URL(string: "wss://api.foracross.com/socket.io/?EIO=3&transport=websocket")!)
    
    func connect() {
        task.resume()
        task.receive(completionHandler: self.receiveMessage)
        self.pingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.ping()
        })
    }
    
    func ping() {
        task.send(.string("2")) { error in
            print(error)
        }
    }
    
    func receiveMessage(result: Result<URLSessionWebSocketTask.Message, Error>)  {
        switch result {
        case .success(let message):
            print(message)
        case .failure(let error):
            print(error)
        }
        
        self.task.receive(completionHandler: self.receiveMessage)
    }
    
    
    
}
