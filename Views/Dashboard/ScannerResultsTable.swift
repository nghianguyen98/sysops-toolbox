import SwiftUI

struct ScannerResultsTable: View {
    let hosts: [ScannedHost]
    
    var body: some View {
        Table(hosts) {
            TableColumn("IP Address") { host in
                HStack {
                    Circle()
                        .fill(host.isOnline ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .shadow(color: host.isOnline ? .green.opacity(0.8) : .clear, radius: 2)
                    Text(host.ipAddress)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
            }
            .width(min: 140, ideal: 160)
            
            TableColumn("Ping") { host in
                if let ms = host.pingTime {
                    Text("\(Int(ms)) ms")
                        .foregroundStyle(.secondary)
                } else {
                    Text("[n/a]")
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .width(60)
            
            TableColumn("Hostname") { host in
                Text(host.hostname ?? "[n/s]")
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 150)
            
            TableColumn("Ports [3+]") { host in
                if host.openPorts.isEmpty {
                    Text("[n/s]")
                        .foregroundStyle(.secondary.opacity(0.5))
                } else {
                    Text(host.openPorts.map { String($0) }.joined(separator: ", "))
                        .foregroundStyle(.primary)
                }
            }
            
            TableColumn("Web Detect") { host in
                Text(host.webBanner ?? "[n/a]")
                    .foregroundStyle(host.webBanner != nil ? Color.blue : Color.secondary.opacity(0.5))
            }
        }
    }
}
