import SwiftUI

struct LANScannerView: View {
    @ObservedObject var viewModel: LANScannerViewModel
    @FocusState private var isSubnetFocused: Bool
    
    var body: some View {
        ToolCard(title: "LAN Scanner", icon: "network.badge.shield.half.filled") {
            VStack(alignment: .leading, spacing: 12) {
                // Input Row
                // Input Section (Compact Combo Box)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Subnet")
                        .font(.callout)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    HStack(spacing: 8) {
                        // Combo Box using Standard TextField Style
                        TextField("e.g. 192.168.1.0", text: $viewModel.subnet)
                            .textFieldStyle(.roundedBorder)
                            .focused($isSubnetFocused)
                            // Add padding to right so text doesn't overlap the chevron
                            .padding(.trailing, 25)
                            .overlay(alignment: .trailing) {
                                // Dropdown Menu embedded
                                Menu {
                                    Text("Detected Subnets").font(.callout).foregroundStyle(.secondary)
                                    ForEach(viewModel.availableInterfaces) { interface in
                                        Button(action: {
                                            viewModel.subnet = interface.subnet
                                            isSubnetFocused = false
                                        }) {
                                            if interface.name == "en0" {
                                                Label("\(interface.ip) (WiFi)", systemImage: "wifi")
                                            } else {
                                                Label("\(interface.ip) (\(interface.name))", systemImage: "network")
                                            }
                                        }
                                    }
                                    Divider()
                                    Button("Refresh Interfaces") {
                                        viewModel.loadInterfaces()
                                    }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .frame(width: 25, height: 25)
                                        .contentShape(Rectangle())
                                }
                                .menuStyle(.borderlessButton)
                                .menuIndicator(.hidden) // Fixes double arrow on macOS
                                .padding(.trailing, 4)
                            }
                        
                        // Scan Button
                        if viewModel.isScanning {
                            Button(action: { viewModel.stopScan() }) {
                                Image(systemName: "stop.fill")
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.bordered)
                            .tint(AppTheme.neonRed)
                        } else {
                            Button(action: { viewModel.startScan() }) {
                                Label("Scan", systemImage: "play.fill")
                                    .frame(height: 20)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.neonBlue)
                        }
                    }
                }
                
                // Progress
                if viewModel.isScanning {
                    ProgressView(value: viewModel.progress)
                        .tint(AppTheme.neonPurple)
                }
            }
        }
    }
}

// MARK: - Subviews
struct HostRow: View {
    let host: ScannedHost
    
    var body: some View {
        HStack(spacing: 12) {
            // Online Indicator
            Circle()
                .fill(host.isOnline ? AppTheme.neonGreen : AppTheme.neonRed)
                .frame(width: 10, height: 10)
                .shadow(color: host.isOnline ? AppTheme.neonGreen.opacity(0.6) : .clear, radius: 4)
            
            // IP
            Text(host.ipAddress)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
            
            Spacer()
            
            // Open Ports Badges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(host.openPorts, id: \.self) { port in
                        PortBadge(port: port)
                    }
                }
            }
            .frame(height: 30)
        }
        .padding(12)
        .background(AppTheme.bgInput) // Slightly different dark BG for row
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
    }
}

struct PortBadge: View {
    let port: Int
    
    var serviceName: String {
        switch port {
        case 21: return "FTP"
        case 22: return "SSH"
        case 23: return "Telnet"
        case 80: return "HTTP"
        case 443: return "HTTPS"
        case 3389: return "RDP"
        case 5900: return "VNC"
        case 8080: return "Web"
        case 8291: return "Winbox"
        default: return String(port)
        }
    }
    
    var badgeColor: Color {
        // Semantic coloring
        switch port {
        case 22, 3389, 5900: return AppTheme.neonOrange // Remote Access
        case 80, 443, 8080: return AppTheme.neonCyan // Web
        case 21, 23: return AppTheme.neonRed // Insecure
        default: return AppTheme.textSecondary
        }
    }
    
    var badgeIcon: String {
        switch port {
        case 21: return "externaldrive.fill"
        case 22: return "terminal.fill"
        case 23: return "phone.connection"
        case 80: return "globe"
        case 443: return "lock.fill"
        case 3389: return "display"
        case 5900: return "cursorarrow.rays"
        case 8080: return "gearshape.fill"
        case 8291: return "server.rack"
        default: return "network"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badgeIcon)
                .font(.footnote)
            Text(serviceName)
                .font(.footnote.bold())
            Text(":\(port)")
                .font(.footnote)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.2))
        .foregroundStyle(badgeColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(badgeColor.opacity(0.4), lineWidth: 1)
        )
    }
}
