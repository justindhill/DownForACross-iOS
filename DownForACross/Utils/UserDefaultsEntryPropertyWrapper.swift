//
//  UserDefaultsEntryPropertyWrapper.swift
//  DownForACross
//
//  Created by Justin Hill on 2/15/24.
//

import Foundation

@propertyWrapper class UserDefaultsEntry<T> {
    
    private let domainPrefix: String = "com.justinhill.DownForACross."
    
    enum Value {
        case uninitialized
        case `nil`
        case value(T)
    }
    
    var key: String
    var backingValue: Value
    var wrappedValue: Any? {
        set {
            UserDefaults.standard.setValue(newValue, forKeyPath: self.key)
            if let newValue {
                self.backingValue = .value(newValue as! T)
            }
        }
        
        get {
            switch backingValue {
                case .uninitialized:
                    if let value = UserDefaults.standard.value(forKeyPath: self.key) {
                        self.backingValue = .value(value as! T)
                        return value as! T
                    } else {
                        self.backingValue = .nil
                        return nil
                    }
                case .nil:
                    return nil
                case .value(let value):
                    return value
            }
        }
    }
    
    init(key: String) {
        self.backingValue = .uninitialized
        self.key = self.domainPrefix + key
    }
    
}
