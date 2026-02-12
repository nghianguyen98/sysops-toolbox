
import SwiftUI

struct LogRow: View {
    let log: LogEntry
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            // Status Icon
            Image(systemName: iconName(for: log.type))
                .foregroundColor(colorForLog(log.type))
                .font(.system(size: 12, weight: .bold))
            
            // Timestamp
            Text(log.timestamp, style: .time)
                .font(.footnote.monospacedDigit())
                .foregroundColor(.secondary)
            
            // Message
            Text(log.message)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func iconName(for type: LogType) -> String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .debug: return "terminal.fill"
        }
    }
    
    private func colorForLog(_ type: LogType) -> Color {
        switch type {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .debug: return .gray
        }
    }
}
