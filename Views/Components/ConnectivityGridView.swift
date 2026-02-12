import SwiftUI

struct ConnectivityGridView: View {
    let history: [Bool]
    

    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Connectivity history")
                .fontProDisplay(.caption, weight: .semibold)
                .foregroundStyle(AppTheme.textSecondary)
            
            // "Signal Bar" Visualization
            HStack(spacing: 3) {
                ForEach(0..<60, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(colorForIndex(index))
                        .frame(height: 20) // Sleek height
                        // Dynamic width handled by HStack spacing, but sticking to small bars
                        .frame(maxWidth: .infinity) 
                }
            }
            .frame(height: 20)
            .background(AppTheme.bgSecondary.opacity(0.1))
            .cornerRadius(4)
        }
    }
    
    func colorForIndex(_ index: Int) -> Color {
        // history is [oldest, ..., newest]
        // We want to display 60 items.
        // Let's say we align them so the newest is at the end (index 59).
        
        let offset = 60 - history.count
        // If index < offset, it's a placeholder (not recorded yet)
        if index < offset {
            return AppTheme.bgSecondary.opacity(0.3)
        }
        
        let historyIndex = index - offset
        if historyIndex < history.count {
            return history[historyIndex] ? AppTheme.neonGreen : AppTheme.neonRed.opacity(0.5)
        }
        
        return AppTheme.bgSecondary.opacity(0.3)
    }
}
