
import SwiftUI

struct PortScanView: View {
    @ObservedObject var portScanService: PortScanService
    @State private var targetIP: String = "127.0.0.1"
    @State private var startPort: String = "80"
    @State private var endPort: String = "100"
    @State private var selectedProtocol: ScanProtocol = .tcp
    
    var body: some View {
        ToolCard(title: "Port Scanner", icon: "waveform.path.ecg") {
            VStack(alignment: .leading, spacing: 12) {
                // Target
                TextField("Target IP", text: $targetIP)
                    .textFieldStyle(.roundedBorder)
                
                // Ports
                VStack(alignment: .leading, spacing: 5) {
                    Text("Port Range:")
                         .font(.callout)
                         .foregroundStyle(AppTheme.textSecondary)
                    
                    HStack {
                        TextField("Start", text: $startPort)
                            .textFieldStyle(.roundedBorder)
                        Text("-")
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("End", text: $endPort)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                // Protocol
                HStack {
                    Text("Protocol:")
                         .font(.callout)
                         .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Picker("", selection: $selectedProtocol) {
                        Text("TCP").tag(ScanProtocol.tcp)
                        Text("UDP").tag(ScanProtocol.udp)
                    }
                    .labelsHidden()
                    .fixedSize() // Prevent picker from expanding too much
                }
                
                PresetMenu(startPort: $startPort, endPort: $endPort)
                
                // Actions
                if portScanService.isScanning {
                    VStack(spacing: 8) {
                        ProgressView(value: portScanService.progress)
                            .tint(AppTheme.neonCyan)
                        
                        HStack {
                            Text("\(Int(portScanService.progress * 100))%")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            Button("Stop") {
                                portScanService.stopScan()
                            }
                            .buttonStyle(.bordered)
                            .tint(AppTheme.neonRed)
                            .controlSize(.small)
                        }
                    }
                } else {
                    Button(action: {
                        guard let start = Int(startPort), let end = Int(endPort) else { return }
                        portScanService.scanPorts(targetIP: targetIP, startPort: start, endPort: end, protocol: selectedProtocol)
                    }) {
                        Text("Start Scan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.neonCyan) // Neon action color
                    .disabled(targetIP.isEmpty)
                    .foregroundStyle(AppTheme.bgDark) // Dark text on bright button
                }
            }
        }
    }
}

private struct PresetMenu: View {
    @Binding var startPort: String
    @Binding var endPort: String
    
    var body: some View {
        Menu("Common Presets") {
            Menu("Basic & Web") {
                Button("Web (80, 443)") { startPort = "80"; endPort = "443" }
                Button("Alt Web (8080, 8443)") { startPort = "8080"; endPort = "8443" }
                Button("SSH (22)") { startPort = "22"; endPort = "22" }
                Button("FTP (21)") { startPort = "21"; endPort = "21" }
                Button("DNS (53)") { startPort = "53"; endPort = "53" }
            }
            
            Menu("Email") {
                Button("SMTP (25, 587)") { startPort = "25"; endPort = "587" }
                Button("IMAP (143, 993)") { startPort = "143"; endPort = "993" }
                Button("POP3 (110, 995)") { startPort = "110"; endPort = "995" }
            }
            
            Menu("Databases") {
                Button("MySQL (3306)") { startPort = "3306"; endPort = "3306" }
                Button("PostgreSQL (5432)") { startPort = "5432"; endPort = "5432" }
                Button("SQL Server (1433)") { startPort = "1433"; endPort = "1433" }
                Button("MongoDB (27017)") { startPort = "27017"; endPort = "27017" }
                Button("Redis (6379)") { startPort = "6379"; endPort = "6379" }
                Button("Memcached (11211)") { startPort = "11211"; endPort = "11211" }
            }
            
            Menu("Infrastructure") {
                Button("RDP (3389)") { startPort = "3389"; endPort = "3389" }
                Button("VNC (5900)") { startPort = "5900"; endPort = "5900" }
                Button("LDAP (389, 636)") { startPort = "389"; endPort = "636" }
                Button("MQTT (1883)") { startPort = "1883"; endPort = "1883" }
            }
            
            Menu("Ranges") {
                Button("Common (0-1024)") { startPort = "0"; endPort = "1024" }
                Button("Dev Ports (3000-8080)") { startPort = "3000"; endPort = "8080" }
                Button("All Ports (1-65535)") { startPort = "1"; endPort = "65535" }
            }
        }
        .menuStyle(.borderlessButton)
        .padding(.bottom, 5)
    }
}
