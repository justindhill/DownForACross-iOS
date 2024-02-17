//
//  UserDefaultsEntryPropertyWrapper.swift
//  DownForACross
//
//  Created by Justin Hill on 2/15/24.
//

import Foundation

fileprivate let jsonEncoder: JSONEncoder = JSONEncoder()
fileprivate let jsonDecoder: JSONDecoder = JSONDecoder()

@propertyWrapper class UserDefaultsEntry<T: Codable> {
    
    private let domainPrefix: String = "com.justinhill.DownForACross."
    
    private var defaultValue: T
    var key: String
    var wrappedValue: T {
        set {
            let encoded = try! jsonEncoder.encode(newValue)
            UserDefaults.standard.setValue(encoded, forKey: self.key)
        }
        
        get {
            if let value = UserDefaults.standard.value(forKey: self.key) as? Data,
               let decodedValue = try? jsonDecoder.decode(T.self, from: value) {
                return decodedValue
            } else {
                return self.defaultValue
            }
        }
    }
    
    init(wrappedValue: T, key: String) {
        self.key = self.domainPrefix + key
        self.defaultValue = wrappedValue
    }
    
}
