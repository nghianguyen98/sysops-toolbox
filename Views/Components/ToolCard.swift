
import SwiftUI

struct ToolCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    @State private var isExpanded: Bool = true
    @State private var isHovering: Bool = false
    
    public init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ProHeaderWithIcon(title: title, icon: icon, color: AppTheme.neonGreen)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(AppTheme.textSecondary)
                    .animation(.spring(), value: isExpanded)
            }
            .padding(16)
            .background(AppTheme.bgSecondary.opacity(0.3)) // Slight header distinction
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
            
            // Content
            if isExpanded {
                Divider().background(AppTheme.border.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 16) {
                    content
                }
                .padding(20)
                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .background(AppTheme.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            AppTheme.border.opacity(0.5),
                            AppTheme.border.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(isHovering ? 0.3 : 0.15), radius: isHovering ? 15 : 8, x: 0, y: isHovering ? 6 : 4)
        .scaleEffect(isHovering ? 1.005 : 1.0)
        .animation(.spring(response: 0.3), value: isHovering)
        .onHover { hover in
            isHovering = hover
        }
    }
}
