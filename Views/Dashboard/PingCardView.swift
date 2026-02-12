
import SwiftUI

struct PingCardView: View {
    @ObservedObject var monitor: PingMonitor
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Leading Icon (OS/Type)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(latencyColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "server.rack")
                    .font(.system(size: 20))
                    .foregroundStyle(latencyColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(monitor.hostname)
                    .font(.system(size: 15, weight: .semibold)) // Slightly bigger, bolder
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if monitor.status == .active {
                        Text("\(Int(monitor.currentLatency))ms")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(latencyColor)
                    } else if monitor.status == .down {
                        Text("Unreachable")
                             .font(.body)
                             .foregroundStyle(AppTheme.neonRed)
                    } else {
                        Text("Idle")
                             .font(.body)
                             .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            
            // Latency Sparkline
            // Latency Sparkline (Responsive)
            if !monitor.history.isEmpty {
                SparklineView(data: monitor.history, color: latencyColor)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .opacity(monitor.status == .active ? 1.0 : 0.3)
            } else {
                Spacer() // Keep spacer if no history yet
            }
            
            // Actions
            HStack(spacing: 8) {
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(AppTheme.neonRed.opacity(0.8))
                        .padding(8)
                        .background(Circle().fill(AppTheme.bgDark.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .help("Remove Host")

                // Start/Stop Toggle
                Button(action: {
                    if monitor.status == .active {
                        monitor.stop()
                    } else {
                        monitor.start()
                    }
                }) {
                    Image(systemName: monitor.status == .active ? "stop.fill" : "play.fill")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(8)
                        .background(Circle().fill(AppTheme.bgDark.opacity(0.5)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppTheme.bgCard)
        .cornerRadius(12)
    }
    
    private var latencyColor: Color {
        if monitor.status == .down { return AppTheme.neonRed }
        let lat = monitor.currentLatency
        if lat < 50 { return AppTheme.neonCyan } // Blue (Primary) for best
        if lat < 150 { return AppTheme.neonGreen }
        if lat < 300 { return AppTheme.neonOrange } // Warning level
        return AppTheme.neonRed
    }
}

private struct StatusIndicator: View {
    let status: PingStatus
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.8), radius: 4) // Stronger glow
    }
    
    var color: Color {
        switch status {
        case .active: return AppTheme.neonGreen
        case .down: return AppTheme.neonRed
        case .idle: return AppTheme.textSecondary
        }
    }
}
