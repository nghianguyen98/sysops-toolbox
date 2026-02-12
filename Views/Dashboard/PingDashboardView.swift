
import SwiftUI
import Charts
import Combine

// MARK: - Dashboard View (Pro Max)
struct PingDashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var newHost = ""
    @State private var hoveredCard: UUID? // For hover effects
    
    // Grid Setup
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header / Controls
                headerView
                
                if viewModel.monitors.isEmpty {
                    emptyStateView
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.monitors) { monitor in
                            DashboardMetricCard(monitor: monitor) {
                                viewModel.removeMonitor(monitor)
                            }
                            .scaleEffect(hoveredCard == monitor.id ? 1.02 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hoveredCard)
                            .onHover { isHovering in
                                if isHovering { hoveredCard = monitor.id }
                                else if hoveredCard == monitor.id { hoveredCard = nil }
                            }
                        }
                    }
                    .padding(.horizontal, 4) // Slight padding for shadow clipping prevention
                    .padding(.bottom, 20)
                }
            }
            .padding(24)
        }
        .background(AppTheme.bgDark.opacity(0.5)) // Subtle dark background behind scan
        .navigationTitle("Live Monitor")
    }
    
    // MARK: - Subviews
    
    var headerView: some View {
        HStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Add Host (e.g. 1.1.1.1)", text: $newHost)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .rounded))
                    .onSubmit { addHost() }
            }
            .padding(12)
            .background(.thinMaterial) // Glassy input
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            Button(action: addHost) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(AppTheme.neonCyan)
                    .foregroundStyle(.black)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.neonCyan.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain) // remove default button styling
            .disabled(newHost.isEmpty)
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.neonCyan.opacity(0.3))
                .padding(.top, 60)
            
            Text("No Active Monitors")
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text("Add a host above to start tracking latency in real-time.")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func addHost() {
        guard !newHost.isEmpty else { return }
        withAnimation(.spring()) {
            viewModel.addMonitor(hostname: newHost)
        }
        newHost = ""
    }
}

// MARK: - Components

struct DashboardMetricCard: View {
    @ObservedObject var monitor: PingMonitor
    var onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Row: Hostname & Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(monitor.hostname)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    HStack(spacing: 6) {
                        StatusPill(status: monitor.status)
                        if monitor.status == .active {
                            Text("Active Pinging")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Latency Big Number
                if monitor.status == .active {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(Int(monitor.currentLatency))")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(metricColor)
                            .contentTransition(.numericText(countsDown: false))
                        Text("ms")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Middle: Heartbeat Graph
            HeartbeatGraph(data: monitor.history, color: metricColor)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Bottom Row: Actions
            HStack {
                Text("Last 5m")
                     .font(.footnote)
                     .foregroundStyle(.tertiary)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(8)
                        .background(.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0) // Only show on hover for cleaner look? Or keep visible?
                .animation(.easeInOut, value: isHovering)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial) // Variable Blur
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5) // Soft Shadow
        .onHover { hover in isHovering = hover }
    }
    
    private var metricColor: Color {
        switch monitor.status {
        case .down: return .red
        case .idle: return .gray
        case .active:
            if monitor.currentLatency < 50 { return AppTheme.neonCyan }
            if monitor.currentLatency < 150 { return AppTheme.neonOrange } // Tweaked for visual pop
            return .red
        }
    }
}

struct HeartbeatGraph: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Latency", value)
                )
                .interpolationMethod(.catmullRom) // Smooth curves
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                
                AreaMark(
                    x: .value("Time", index),
                    y: .value("Latency", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        // Add a pulsing effect if updating?
    }
}

struct StatusPill: View {
    let status: PingStatus
    
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 1.0 : 0.6)
                .animation(status == .active ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: isPulsing)
            
            Text(statusTitle)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
        .onAppear {
            if status == .active { isPulsing = true }
        }
        .onChange(of: status) { _, newStatus in
            isPulsing = (newStatus == .active)
        }
    }
    
    var statusColor: Color {
        switch status {
        case .active: return AppTheme.neonGreen
        case .down: return .red
        case .idle: return .gray
        }
    }
    
    var statusTitle: String {
        switch status {
        case .active: return "ONLINE"
        case .down: return "OFFLINE"
        case .idle: return "PAUSED"
        }
    }
}
