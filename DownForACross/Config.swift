//
//  Config.swift
//  DownForACross
//
//  Created by Justin Hill on 2/9/24.
//

import Foundation

enum Config {
    #if DFAC_LOCAL_SERVER
    static let apiBaseURLComponents = URLComponents(string: "http://localhost:3021")!
    static let siteBaseURLComponents = URLComponents(string: "http://localhost:3020")!
    #else
    static let apiBaseURLComponents = URLComponents(string: "https://api.foracross.com")!
    static let siteBaseURLComponents = URLComponents(string: "https://downforacross.com")!
    #endif
}
