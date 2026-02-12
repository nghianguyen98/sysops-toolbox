import SwiftUI

struct TracerouteView: View {
    @ObservedObject var service: TracerouteService
    @State private var targetHost = "google.com"
    
    var body: some View {
        ToolCard(title: "Network Path Analysis", icon: "arrow.triangle.branch") {
            VStack(spacing: 0) {
                // Input Header
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "terminal.fill")
                            .foregroundStyle(AppTheme.neonCyan)
                        TextField("Host / IP Address", text: $targetHost)
                            .textFieldStyle(.plain)
                            .foregroundStyle(AppTheme.textPrimary)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(12)
                    .background(AppTheme.bgDark.opacity(0.8))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                    
                    Button(action: {
                        if service.isRunning {
                            service.stopTrace()
                        } else {
                            service.startTrace(host: targetHost)
                        }
                    }) {
                        Text(service.isRunning ? "ABORT" : "TRACE")
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .frame(width: 80, height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(service.isRunning ? AppTheme.neonRed : AppTheme.neonCyan)
                }
                .padding(.bottom, 24)
                
                // Data Table Header
                HStack {
                    Text("HOP")
                        .frame(width: 40, alignment: .leading)
                    Text("HOST / IP")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("VISUALIZATION")
                        .frame(width: 150, alignment: .leading)
                    Text("LATENCY")
                        .frame(width: 100, alignment: .trailing)
                }
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                Divider().background(AppTheme.border)
                
                // Data Rows
                if service.hops.isEmpty && !service.isRunning {
                    ContentUnavailableView("Ready to Trace", systemImage: "arrow.triangle.branch", description: Text("Enter a target host to analyze the network path."))
                } else {
                    ScrollViewReader { proxy in
                        VStack(spacing: 0) {
                            ForEach(Array(service.hops.enumerated()), id: \.element.id) { index, hop in
                                TraceRow(hop: hop, previousLatency: index > 0 ? service.hops[index-1].latency : nil)
                                    .id(hop.number)
                                Divider().background(AppTheme.border.opacity(0.3))
                            }
                        }
                        .onChange(of: service.hops.count) {
                            if let last = service.hops.last {
                                withAnimation { proxy.scrollTo(last.number, anchor: .bottom) }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TraceRow: View {
    let hop: TracerouteHop
    let previousLatency: Double?
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 1. Hop Number
            Text("\(hop.number)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(AppTheme.neonCyan)
                .frame(width: 40, alignment: .leading)
            
            // 2. Hostname Details
            VStack(alignment: .leading, spacing: 2) {
                Text(hop.hostname)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                
                if !hop.ip.isEmpty && hop.ip != hop.hostname && hop.ip != "*" {
                    Text(hop.ip)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                } else if hop.status == .timeout {
                    Text("Request Timed Out")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 8)
            
            // 3. Visualization (Latency Bar)
            LatencyBar(latency: hop.latency, status: hop.status)
                .frame(width: 150)
                .padding(.trailing, 16)
            
            // 4. Latency Numeric + Delta Badge
            VStack(alignment: .trailing, spacing: 2) {
                if let lat = hop.latency {
                    Text(String(format: "%.1f ms", lat))
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundStyle(latencyColor(lat))
                    
                    if let prev = previousLatency {
                        let delta = max(0, lat - prev)
                        Text(String(format: "+%.1f", delta))
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(deltaColor(delta))
                    }
                } else if hop.status == .running {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Text("*")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(hop.number % 2 == 0 ? AppTheme.bgDark.opacity(0.3) : Color.clear)
    }
    
    private func latencyColor(_ lat: Double) -> Color {
        if lat < 50 { return AppTheme.neonGreen }
        if lat < 150 { return AppTheme.neonOrange }
        return AppTheme.neonRed
    }
    
    private func deltaColor(_ delta: Double) -> Color {
        if delta < 10 { return AppTheme.textSecondary }
        if delta < 50 { return AppTheme.neonOrange }
        return AppTheme.neonRed
    }
}

struct LatencyBar: View {
    let latency: Double?
    let status: TracerouteHop.HopStatus
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(AppTheme.border.opacity(0.3))
                    .frame(height: 6)
                
                // Active Bar
                if let lat = latency {
                    let width = min(geo.size.width, geo.size.width * (CGFloat(lat) / 300.0)) // Cap at 300ms for full width
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [barColor(lat).opacity(0.6), barColor(lat)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, width), height: 6)
                } else if status == .running {
                    Capsule()
                        .fill(AppTheme.neonCyan.opacity(0.5))
                        .frame(width: 20, height: 6)
                }
            }
            .frame(height: geo.size.height)
        }
        .frame(height: 6)
    }
    
    private func barColor(_ lat: Double) -> Color {
        if lat < 50 { return AppTheme.neonGreen }
        if lat < 150 { return AppTheme.neonOrange }
        return AppTheme.neonRed
    }
}

