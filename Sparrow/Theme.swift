import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// SPARROW palette: the reference's red becomes `base`, its black becomes `ink`.
enum Theme {
    /// Background, and text on top of `ink` panels.
    static let base = Color(hex: 0x43464C)
    /// Lettering, panels, map lines.
    static let ink = Color(hex: 0xADB8C7)

    static let cornerRadius: CGFloat = 8

    /// Condensed, heavy type in the spirit of the reference's DIN-style numerals.
    static func font(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }
}
