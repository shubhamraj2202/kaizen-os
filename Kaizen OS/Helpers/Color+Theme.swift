//
//  Color+Theme.swift
//  Kaizen OS
//

import SwiftUI

extension Color {
    // Primary palette
    static let kaizenTeal   = Color(hex: "#00E5C8")
    static let kaizenPurple = Color(hex: "#6450FF")
    static let kaizenCoral  = Color(hex: "#FF6B6B")
    static let kaizenOrange = Color(hex: "#FF8C42")

    // Backgrounds
    static let bgPrimary    = Color(hex: "#090E1A")
    static let bgCard       = Color(hex: "#0D1321")
    static let bgElevated   = Color(hex: "#141C2E")

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.5)
    static let textTertiary  = Color.white.opacity(0.3)

    // Borders
    static let borderDefault = Color.white.opacity(0.07)
    static let borderAccent  = Color(hex: "#00E5C8").opacity(0.25)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
