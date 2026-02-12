
import SwiftUI

struct PasswordGenView: View {
    @State private var password = ""
    @State private var length = 16.0
    @State private var includeUpper = true
    @State private var includeLower = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var excludeAmbiguous = true
    @State private var lastCopiedTime: Date? = nil
    
    // Derived State
    @State private var strengthScore: Double = 0
    
    var body: some View {
        ToolCard(title: "Password Generator", icon: "lock.shield.fill") {
            VStack(spacing: 24) {
                // Password Display Area
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.bgDark.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(strengthColor.opacity(0.3), lineWidth: 1)
                            )
                        
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(password)
                                    .font(.system(.title2, design: .monospaced)) // Larger font
                                    .fontWeight(.bold)
                                    .foregroundStyle(strengthColor) // Color text by strength
                                    .padding(.vertical, 12)
                            }
                            
                            Spacer()
                            
                            Button(action: copyToClipboard) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(isCopied ? AppTheme.neonGreen : AppTheme.textSecondary)
                                    .padding(10)
                                    .background(AppTheme.bgCard)
                                    .clipShape(Circle())
                                    .shadow(color: isCopied ? AppTheme.neonGreen.opacity(0.4) : .clear, radius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 80)
                    // Removed neonGlow
                    
                    // Modern Segmented Strength Meter
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(strengthText)
                                .font(.body.bold())
                                .foregroundStyle(strengthColor)
                            
                            Spacer()
                            
                            Text("\(Int(length)) chars")
                                .font(.body.monospaced())
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                        HStack(spacing: 4) {
                            ForEach(0..<4) { index in
                                Capsule()
                                    .fill(strengthBarColor(for: index))
                                    .frame(height: 6)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: strengthScore)
                            }
                        }
                    }
                }
                
                // Controls
                VStack(spacing: 20) {
                    // Length Slider
                    VStack(alignment: .leading, spacing: 10) {
                        Text("LENGTH")
                            .font(.callout.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        HStack(spacing: 16) {
                            Slider(value: $length, in: 4...64, step: 1)
                                .tint(AppTheme.neonCyan)
                            
                            Text("\(Int(length))")
                                .font(.system(.body, design: .monospaced).bold())
                                .frame(width: 32)
                                .foregroundStyle(AppTheme.neonCyan)
                        }
                    }
                    .padding(16) // Increased padding
                    .background(AppTheme.bgSecondary.opacity(0.3))
                    .cornerRadius(12)
                    
                    // Options Grid
                    VStack(alignment: .leading, spacing: 0) {
                        Text("COMPLEXITY")
                            .font(.callout.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.bottom, 12)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ToggleOption(title: "A-Z", isOn: $includeUpper)
                            ToggleOption(title: "a-z", isOn: $includeLower)
                            ToggleOption(title: "0-9", isOn: $includeNumbers)
                            ToggleOption(title: "!@#", isOn: $includeSymbols)
                        }
                        
                        Divider().padding(.vertical, 12).background(AppTheme.border.opacity(0.3))
                        
                        Toggle(isOn: $excludeAmbiguous) {
                            Text("No Ambiguous (O, 0, l, 1)")
                                .font(.body)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.neonPurple))
                    }
                    .padding(16)
                    .background(AppTheme.bgSecondary.opacity(0.3))
                    .cornerRadius(12)
                    
                    // Action
                    Button(action: generatePassword) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("GENERATE")
                        }
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.neonCyan)
                        .foregroundStyle(.black) // Black text on neon
                        .cornerRadius(12)
                        .shadow(color: AppTheme.neonCyan.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                        .scaleEffect(isPressed ? 0.98 : 1.0)
                        .animation(.spring(), value: isPressed)
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear(perform: calculateAndGenerate)
        .onChange(of: length) { calculateAndGenerate() }
        .onChange(of: includeUpper) { calculateAndGenerate() }
        .onChange(of: includeLower) { calculateAndGenerate() }
        .onChange(of: includeNumbers) { calculateAndGenerate() }
        .onChange(of: includeSymbols) { calculateAndGenerate() }
    }
    
    // Animation State
    @State private var isPressed = false
    @State private var isCopied = false
    
    // MARK: - Logic
    
    private func calculateAndGenerate() {
        generatePassword()
        calculateStrength()
    }
    
    private func generatePassword() {
        let upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lower = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*"
        let ambiguous = "l1Io0O"
        
        var pool = ""
        if includeUpper { pool += upper }
        if includeLower { pool += lower }
        if includeNumbers { pool += numbers }
        if includeSymbols { pool += symbols }
        
        if excludeAmbiguous {
            pool = pool.filter { !ambiguous.contains($0) }
        }
        
        guard !pool.isEmpty else {
            password = "---"
            return
        }
        
        password = String((0..<Int(length)).compactMap { _ in pool.randomElement() })
    }
    
    // Improved Strength Algorithm
    private func calculateStrength() {
        var score = 0.0
        
        // Length Weight (up to 40 pts)
        score += min(length * 3, 40)
        
        // Complexity Weight (up to 60 pts)
        if includeUpper { score += 15 }
        if includeLower { score += 15 }
        if includeNumbers { score += 15 }
        if includeSymbols { score += 15 }
        
        // Symbol Variety Bonus
        if length > 12 && includeNumbers && includeSymbols { score += 10 }
        
        strengthScore = min(score, 100)
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(password, forType: .string)
        withAnimation { isCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isCopied = false }
        }
    }
    
    // MARK: - Visual Helpers
    
    private var strengthColor: Color {
        if strengthScore < 40 { return AppTheme.neonRed }
        if strengthScore < 65 { return AppTheme.neonOrange }
        if strengthScore < 85 { return AppTheme.neonCyan }
        return AppTheme.neonGreen
    }
    
    private var strengthText: String {
        if strengthScore < 40 { return "WEAK" }
        if strengthScore < 65 { return "FAIR" }
        if strengthScore < 85 { return "GOOD" }
        return "EXCELLENT"
    }
    
    // Returns color for specific segment index (0..3)
    private func strengthBarColor(for index: Int) -> Color {
        // active segments
        let threshold = Double(index + 1) * 25.0
        if strengthScore >= (threshold - 20) { // Slight overlap for smoother feel
            return strengthColor
        }
        return AppTheme.bgSecondary.opacity(0.5) // Inactive
    }
}

// Subcomponent for Grid
struct ToggleOption: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: { withAnimation { isOn.toggle() } }) {
            HStack {
                Text(title)
                    .font(.system(.body, design: .monospaced))
                    .bold()
                    .foregroundStyle(isOn ? AppTheme.textPrimary : AppTheme.textSecondary)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundStyle(AppTheme.neonGreen)
                }
            }
            .padding(12)
            .background(isOn ? AppTheme.neonGreen.opacity(0.1) : AppTheme.bgDark.opacity(0.3)) // Slight bg for hit testing
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isOn ? AppTheme.neonGreen.opacity(0.5) : AppTheme.border.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle()) // Crucial for hit testing on Spacer area
        }
        .buttonStyle(.plain)
    }
}
