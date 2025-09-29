//
//  UIColor.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-20.
//
import SwiftUI

// Helper function to convert hex to UIColor
extension UIColor {
    convenience init(hex: String) {
        var newHex = ""
        var isKnownColor: Bool = false
        
        if hex == "primary"{
            newHex = "#0073e6"
            isKnownColor = true
        } else if hex == "secondary"{
            newHex = "#001f3f"
            isKnownColor = true
        } else if hex == "accent"{
            newHex = "#ff4500"
            isKnownColor = true
        }
        if isKnownColor == false {
            var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            if hexSanitized.hasPrefix("#") {
                hexSanitized.removeFirst()
            }
            
            var hexValue: UInt64 = 0
            Scanner(string: hexSanitized).scanHexInt64(&hexValue)
            
            let red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(hexValue & 0x0000FF) / 255.0
            
            self.init(red: red, green: green, blue: blue, alpha: 1.0)
        } else {
            var hexSanitized = newHex.trimmingCharacters(in: .whitespacesAndNewlines)
            if hexSanitized.hasPrefix("#") {
                hexSanitized.removeFirst()
            }
            
            var hexValue: UInt64 = 0
            Scanner(string: hexSanitized).scanHexInt64(&hexValue)
            
            let red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(hexValue & 0x0000FF) / 255.0
            
            self.init(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }
}

