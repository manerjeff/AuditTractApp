//
//  Theme.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI

/// Path palette for Audit Tract.
/// sRGB values match the brand sheet hex set.
enum TractColor {
    static let canvas    = Color(red: 0.043, green: 0.051, blue: 0.071) // #0B0D12
    static let card      = Color(red: 0.086, green: 0.102, blue: 0.133) // #161A22
    static let stroke    = Color(red: 0.165, green: 0.192, blue: 0.251) // #2A3140
    static let ink       = Color(red: 0.953, green: 0.941, blue: 0.910) // #F3F0E8
    static let secondary = Color(red: 0.604, green: 0.639, blue: 0.698) // #9AA3B2
    static let label     = Color(red: 0.431, green: 0.471, blue: 0.533) // #6E7888
    static let copper    = Color(red: 0.878, green: 0.541, blue: 0.235) // #E08A3C
    static let copperDim = Color(red: 0.227, green: 0.165, blue: 0.110) // #3A2A1C
    static let action    = Color(red: 0.773, green: 0.416, blue: 0.176) // #C56A2D
}

/// Full backward-compatibility mapping for AppColor across all project views
struct AppColor {
    static let bg            = TractColor.canvas
    static let panelTop      = TractColor.card
    static let border        = TractColor.stroke
    static let brand         = TractColor.action
    static let accent        = TractColor.copper
    static let accent1       = TractColor.copper
    static let accent2       = TractColor.action
    static let sub           = TractColor.secondary
    static let premiumPurple = TractColor.action
    static let premiumPink   = TractColor.copper
    static let chipOn        = TractColor.copperDim
    static let chipOff       = TractColor.card
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
