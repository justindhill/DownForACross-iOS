//
//  UIColor+HSLString.swift
//  DownForACross
//
//  Created by Justin Hill on 4/17/24.
//

import UIKit
import RegexBuilder

extension UIColor {

    convenience init(hslString string: String) throws {
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

        self.init(UIColor.HSL(hue: result[hue], saturation: result[saturation], lightness: result[luminance]))
    }
    
}
