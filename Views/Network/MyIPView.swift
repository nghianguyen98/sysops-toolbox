import SwiftUI
import Combine

struct MyIPView: View {
    @StateObject private var trafficMonitor = NetworkTrafficMonitor()
    @StateObject private var geoService = IPGeoService()
    @State private var publicIP: String = "Loading..."
    @State private var localIP: String = "Scanning..."
    @State private var interfaceName: String = "en0"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Live Traffic (Bandwidth + Chart)
                VStack(spacing: 16) {
                    ProHeaderWithIcon(title: "Live Traffic", icon: "chart.xyaxis.line", color: AppTheme.neonBlue)
                    
                    HStack(alignment: .top) {
                        BandwidthHeaderItem(title: "Download", value: trafficMonitor.currentDownloadSpeed, color: AppTheme.neonBlue)
                        Spacer()
                        BandwidthHeaderItem(title: "Upload", value: trafficMonitor.currentUploadSpeed, color: .primary)
                    }
                    
                    TrafficChartView(history: trafficMonitor.history)
                }
                .padding()
                .bentoStyle() // Uses DesignSystem
                .padding(.horizontal)
                
                // 2. Connectivity History
                VStack(alignment: .leading, spacing: 16) {
                    ProHeaderWithIcon(title: "Connectivity", icon: "network", color: AppTheme.neonGreen)
                    ConnectivityGridView(history: trafficMonitor.connectivityHistory)
                }
                .padding()
                .bentoStyle()
                .padding(.horizontal)
                
                // 3. Network Details (Consolidated)
                VStack(alignment: .leading, spacing: 24) {
                    ProHeaderWithIcon(title: "Network Details", icon: "doc.text.magnifyingglass", color: AppTheme.neonPurple)
                    
                    VStack(spacing: 20) {
                        // Section: Status
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CONNECTION STATUS")
                                .fontProDisplay(.subheadline, weight: .bold)
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            VStack(spacing: 8) {
                                IPDetailRow(label: "Internet:", value: "UP", valueColor: AppTheme.neonGreen)
                                IPDetailRow(label: "Latency:", value: trafficMonitor.latency, valueColor: .primary)
                                IPDetailRow(label: "Jitter:", value: trafficMonitor.jitter, valueColor: .primary)
                                IPDetailRow(label: "Total DL:", value: trafficMonitor.totalDownload, valueColor: .primary)
                                IPDetailRow(label: "Total UL:", value: trafficMonitor.totalUpload, valueColor: .primary)
                            }
                        }
                        
                        Divider().background(AppTheme.border.opacity(0.3))
                        
                        // Section: Interface
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INTERFACE (\(trafficMonitor.activeInterface))")
                                .fontProDisplay(.subheadline, weight: .bold)
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            VStack(spacing: 8) {
                                IPDetailRow(label: "MAC Addr:", value: trafficMonitor.macAddress, valueColor: .primary)
                                IPDetailRow(label: "Local IP:", value: localIP, valueColor: .primary, showCopy: true)
                                IPDetailRow(label: "Public IP:", value: "\(publicIP)", valueColor: AppTheme.neonCyan, showCopy: true)
                                IPDetailRow(label: "Country:", value: geoService.result?.country ?? "Unknown", valueColor: .primary)
                                IPDetailRow(label: "ISP:", value: geoService.result?.connection?.isp ?? "Unknown", valueColor: .primary)
                            }
                        }
                    }
                }
                .padding()
                .bentoStyle()
                .padding(.horizontal)
                
                // 4. Top Processes
                VStack(alignment: .leading, spacing: 16) {
                    ProHeaderWithIcon(title: "Top Processes", icon: "cpu", color: AppTheme.neonRed)
                    ProcessListView(processes: trafficMonitor.topProcesses)
                }
                .padding()
                .bentoStyle()
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            refreshData()
            trafficMonitor.startMonitoring()
        }
        .onDisappear {
            trafficMonitor.stopMonitoring()
        }
    }
    
    private func refreshData() {
        // Fetch Local IP
        let interfaces = NetworkInterfaceUtils.getInterfaces()
        if let match = interfaces.first(where: { $0.name == trafficMonitor.activeInterface }) {
            localIP = match.ip
        } else if let first = interfaces.first {
            localIP = first.ip
        } else {
            localIP = "Unknown"
        }
        
        // Fetch Public IP
        publicIP = "Loading..."
        guard let url = URL(string: "https://api.ipify.org") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let ip = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.publicIP = ip
                    self.geoService.fetchLocation(for: ip)
                }
            } else {
                DispatchQueue.main.async {
                    self.publicIP = "Error"
                }
            }
        }.resume()
    }
}

struct BandwidthHeaderItem: View {
    let title: String
    let value: String
    let color: Color
    
    var components: (String, String) {
        let parts = value.components(separatedBy: " ")
        if parts.count >= 2 {
            return (parts[0], parts[1])
        }
        return (value, "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(components.0)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(components.1)
                    .fontProDisplay(.body, weight: .medium)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

struct IPDetailRow: View {
    let label: String
    let value: String
    let valueColor: Color
    var iconColor: Color? = nil
    var showCopy: Bool = false
    
    var body: some View {
        HStack {
            if let iconColor = iconColor {
                Rectangle().fill(iconColor).frame(width: 12, height: 12).cornerRadius(2)
            }
            Text(label)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
            
            if showCopy {
                Button(action: {
                    // Extract simple IP cleanly if possible
                    let cleanValue = value.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? value
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cleanValue, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
