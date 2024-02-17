//
//  UserDefaultsOptionalEntry.swift
//  DownForACross
//
//  Created by Justin Hill on 2/15/24.
//

import Foundation

fileprivate let jsonEncoder: JSONEncoder = JSONEncoder()
fileprivate let jsonDecoder: JSONDecoder = JSONDecoder()

@propertyWrapper class UserDefaultsOptionalEntry<T: Codable> {
    
    private let domainPrefix: String = "com.justinhill.DownForACross."
    
    var key: String
    var wrappedValue: T? {
        set {
            let encoded = try! jsonEncoder.encode(newValue)
            UserDefaults.standard.setValue(encoded, forKey: self.key)
        }
        
        get {
            if let value = UserDefaults.standard.value(forKey: self.key) as? Data,
               let decodedValue = try? jsonDecoder.decode(T.self, from: value) {
                return decodedValue
            } else {
                return nil
            }
        }
    }
    
    init(key: String) {
        self.key = self.domainPrefix + key
    }
    
}

@propertyWrapper class UserDefaultsOptionalArchiveEntry<T: NSSecureCoding> {
    
    private let domainPrefix: String = "com.justinhill.DownForACross."
    
    var key: String
    var wrappedValue: T? {
        set {
            var value: Data?
            if let newValue {
                value = try! NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
            }
            UserDefaults.standard.setValue(value, forKey: self.key)
        }
        
        get {
            if let value = UserDefaults.standard.value(forKey: self.key) as? Data,
               let decodedValue = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [T.self], from: value) as? T {
                return decodedValue
            } else {
                return nil
            }
        }
    }
    
    init(key: String) {
        self.key = self.domainPrefix + key
    }
    
}

