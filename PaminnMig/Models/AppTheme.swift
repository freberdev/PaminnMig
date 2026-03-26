import SwiftUI

enum AppTheme {
    static let primaryColor = Color(hex: 0x2D2D2D)
    static let accentColor = Color(hex: 0xFF6B35)
    static let criticalColor = Color(hex: 0xFF3B5C)
    static let successColor = Color(hex: 0x00C48C)
    static let warningColor = Color(hex: 0xFFB423)
    static let backgroundColor = Color(hex: 0xF5F3EF)
    static let surfaceColor = Color.white
    static let textPrimary = Color(hex: 0x1A1A1A)
    static let textSecondary = Color(hex: 0x999490)
    static let subtleBorder = Color(hex: 0xEBE8E3)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
