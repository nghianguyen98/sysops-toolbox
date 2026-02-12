import SwiftUI
import Charts

struct TrafficChartView: View {
    let history: [NetworkTrafficMonitor.HistoryPoint]
    
    private let formatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .binary
        f.allowedUnits = [.useMB, .useKB, .useBytes] // Auto-scale
        f.includesUnit = true
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Chart Area
            Chart {
                ForEach(history) { point in
                    // Area with Gradient
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Bandwidth", point.downloadBytes) // Focusing on Download for the "Blue" look
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hexString: "3b82f6").opacity(0.5), // Bright Blue
                                Color(hexString: "3b82f6").opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    // Top Line stroke
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Bandwidth", point.downloadBytes)
                    )
                    .foregroundStyle(Color(hexString: "3b82f6")) // Solid Blue
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { value in
                    AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.3))
                    AxisValueLabel {
                        if let bytes = value.as(Double.self) {
                            Text(formatBitRate(bytes))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 140) // Increased height slightly to accommodate labels
            .padding(.top, 10)
            
            // Footer Label
            Text("Last 60s")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.leading, 4)
        }
        .padding(12)
        .background(AppTheme.bgSecondary.opacity(0.2)) // Darker chart background
        .cornerRadius(12)
    }
    private func formatBitRate(_ bytes: Double) -> String {
        let bits = bytes * 8
        if bits >= 1_000_000_000 {
            return String(format: "%.1f Gbps", bits / 1_000_000_000)
        } else if bits >= 1_000_000 {
            return String(format: "%.1f Mbps", bits / 1_000_000)
        } else if bits >= 1_000 {
            return String(format: "%.0f Kbps", bits / 1_000)
        } else {
            return String(format: "%.0f bps", bits)
        }
    }
}



