
import SwiftUI

// MARK: - Pro Max Design System
// Based on "Vibrant & Block-based" Intelligence

struct BentoCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.bgCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppTheme.border.opacity(0.6),
                                AppTheme.border.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func bentoStyle() -> some View {
        self.modifier(BentoCardStyle())
    }
    
    // Modern "Fira" style typography
    func fontProDisplay(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        self.font(.system(style, design: .monospaced).weight(weight))
    }
    
    func fontProBody() -> some View {
        self.font(.system(.body, design: .default))
    }
    
    // Neon Glow Effect
    func neonGlow(color: Color, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Reusable Components

struct ProHeaderWithIcon: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .fontProDisplay(.title3, weight: .bold)
                .foregroundStyle(AppTheme.textPrimary)
            
            Spacer()
        }
    }
}
