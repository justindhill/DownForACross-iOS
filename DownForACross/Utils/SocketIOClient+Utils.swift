//
//  SocketIOClient+Utils.swift
//  DownForACross
//
//  Created by Justin Hill on 1/18/24.
//

import SocketIO

extension SocketIOClient {
    func emitWithAckNoOp(_ eventName: String, _ items: SocketData...) {
        self.emitWithAck(eventName, items).timingOut(after: 5, callback: { _ in })
    }
    
    func emitWithAckNoOp(_ eventName: String, _ items: [SocketData]) {
        self.emitWithAck(eventName, items).timingOut(after: 5, callback: { _ in })
    }
}
