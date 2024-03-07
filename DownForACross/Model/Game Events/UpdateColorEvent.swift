//
//  UpdateColorEvent.swift
//  DownForACross
//
//  Created by Justin Hill on 1/18/24.
//

import UIKit
import RegexBuilder

struct UpdateColorEvent: DedupableGameEvent {
    
    var type: String = "updateColor"
    var eventId: String = UUID().uuidString
    
    var gameId: String
    var userId: String
    var color: UIColor
    
    init(payload: [String: Any]) throws {
        self.gameId = ""
        guard let params = payload["params"] as? [String: Any],
              let userId = params["id"] as? String,
              let hslString = params["color"] as? String else {
            throw NSError(domain: "UpdateColorEventErrorDomain", code: 0)
        }
        
        self.userId = userId
        self.color = try Self.parseHSL(string: hslString)
    }
    
    init(gameId: String, userId: String, color: UIColor) {
        self.gameId = gameId
        self.userId = userId
        self.color = color
    }
    
    static func parseHSL(string: String) throws -> UIColor {
        let numberFormatter = NumberFormatter()
        let hue = Reference(CGFloat.self)
        let saturation = Reference(CGFloat.self)
        let luminance = Reference(CGFloat.self)
        
        let floatTransformBlock: (Substring) -> CGFloat? = { match in
            if let floatValue = numberFormatter.number(from: String(match))?.floatValue {
                return CGFloat(floatValue)
            }
            return nil
        }
        
        let hslRegex = Regex {
            "hsl("
            TryCapture(as: hue, { OneOrMore(.any) }, transform: floatTransformBlock)
            ","
            TryCapture(as: saturation, { OneOrMore(.any) }, transform: floatTransformBlock)
            "%,"
            TryCapture(as: luminance, { OneOrMore(.any) }, transform: floatTransformBlock)
            "%)"
        }
        
        guard let result = try hslRegex.firstMatch(in: string) else {
            throw NSError(domain: "UpdateColorEventErrorDomain", code: 1)
        }
        
        return UIColor(UIColor.HSL(hue: result[hue], saturation: result[saturation], lightness: result[luminance]))
    }
    
    var paramsDictionary: [String : Any?] {[
        "id": self.userId,
        "color": self.color.hslString
    ]}
    
}
