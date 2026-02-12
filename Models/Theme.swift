
import AppKit
import SwiftUI

struct AppTheme {
    // MARK: - Restored Deep Blue Theme
    
    // Backgrounds (Adaptive)
    static let bgDark = Color.adaptive(light: "F1F5F9", dark: "11131B") // Original Deep Blue
    static let bgCard = Color.adaptive(light: "FFFFFF", dark: "1F212E") // Original Blue-Grey
    
    // New property mapping to maintain compatibility with new UI components
    static let bgSecondary = Color.adaptive(light: "E2E8F0", dark: "171924") // Mapped to old bgInput style
    
    static let bgInput = Color.adaptive(light: "E2E8F0", dark: "171924") // Original Input Dark
    static let border = Color.adaptive(light: "CBD5E1", dark: "2A2D3C") // Original subtle border
    
    // Accents
    static let neonCyan = Color(hexString: "3B82F6") // Original Blue (Primary)
    static let neonBlue = Color(hexString: "3B82F6") // Alias
    static let neonGreen = Color(hexString: "22C55E") // Original Green
    static let neonPurple = Color(hexString: "A855F7") // Original Purple
    static let neonRed = Color(hexString: "EF4444") // Original Red
    static let neonOrange = Color(hexString: "F97316") // Original Orange
    
    // Text (Adaptive)
    static let textPrimary = Color.adaptive(light: "1E293B", dark: "F8FAFC") // Slate 800 vs White
    static let textSecondary = Color.adaptive(light: "64748B", dark: "94A3B8") // Slate 500 vs Slate 400
    
    // New property mapping
    static let textTertiary = Color.adaptive(light: "94A3B8", dark: "64748B") 
}

extension Color {
    static func adaptive(light: String, dark: String) -> Color {
        let lightColor = NSColor(Color(hexString: light))
        let darkColor = NSColor(Color(hexString: dark))
        
        let dynamicColor = NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return darkColor
            } else {
                return lightColor
            }
        }
        return Color(dynamicColor)
    }
}

extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
            (a, r, g, b) = (1, 1, 1, 0)
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
