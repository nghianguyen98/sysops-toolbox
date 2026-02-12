
import SwiftUI

struct PingView: View {
    @ObservedObject var pingService: PingService
    @State private var hostname: String = "google.com"
    @State private var interval: String = "1.0"
    
    var body: some View {
        ToolCard(title: "Ping", icon: "network") {
            VStack(alignment: .leading, spacing: 12) {
                // Host Input
                TextField("Hostname / IP", text: $hostname)
                    .textFieldStyle(.roundedBorder)
                
                // Interval
                HStack {
                     Text("Interval (s):")
                        .font(.callout)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("1.0", text: $interval)
                        .textFieldStyle(.roundedBorder)
                }

                // Start/Stop Button (Full Width)
                if pingService.isPinging {
                    Button(action: { pingService.stopPing() }) {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.neonRed)
                } else {
                    Button(action: {
                        let intervalValue = Double(interval) ?? 1.0
                        pingService.startPing(host: hostname, interval: intervalValue)
                    }) {
                        Label("Start Ping", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .tint(AppTheme.neonGreen)
                    .disabled(hostname.isEmpty)
                    .foregroundStyle(AppTheme.bgDark)
                }
            }
        }
    }
}
