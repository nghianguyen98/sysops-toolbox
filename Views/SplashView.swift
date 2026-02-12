import SwiftUI

struct SplashView: View {
    @State private var logoScale = 0.8
    @State private var logoOpacity = 0.0
    @State private var textOpacity = 0.0
    @State private var authorOpacity = 0.0
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(hexString: "11131B"), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo & Title Container
                VStack(spacing: 24) {
                    // Logo with "Squircle" clip - Scaled to fill to reduce white border
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Fill to reduce internal whitespace
                        .frame(width: 140, height: 140)
                        .scaleEffect(1.1) // Zoom in slightly to cut off more whitespace
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 36, style: .continuous)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: AppTheme.neonCyan.opacity(0.4), radius: 30, x: 0, y: 10)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    VStack(spacing: 8) {
                        Text("SysOps Toolbox")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, AppTheme.neonCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("v1.0")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                            .tracking(2)
                    }
                    .opacity(textOpacity)
                    .offset(y: textOpacity == 1 ? 0 : 20)
                }
                
                Spacer()
                
                // Author Signature (Bottom)
                HStack(spacing: 6) {
                    Text("crafted by")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                    
                    Text("Nghia Nguyen")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                }
                .padding(.bottom, 40)
                .opacity(authorOpacity)
            }
        }
        .preferredColorScheme(.dark) // Force Dark Mode for Splash Screen
        .onAppear {
            // Animation Sequence
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                textOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 1.0).delay(1.2)) {
                authorOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
