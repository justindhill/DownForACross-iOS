//
//  SharedGame.swift
//  DownForACross
//
//  Created by Justin Hill on 3/28/24.
//

import Foundation
import SharedWithYou

struct SharedGame: Identifiable, Hashable {

    var id: String {
        return self.gameId
    }

    var gameId: String
    var title: String? = nil
    var lastOpened: Date? = nil
    var highlight: SWHighlight?

}
