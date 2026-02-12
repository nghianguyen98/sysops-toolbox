import SwiftUI

struct DNSLookupView: View {
    @StateObject private var service = DNSLookupService()
    @State private var domain = "google.com"
    @State private var selectedType: DNSRecordType = .A
    @State private var dnsServer = ""
    @State private var useShortOutput = false
    
    var body: some View {
        ToolCard(title: "DNS Lookup Tool", icon: "magnifyingglass.circle.fill") {
            VStack(spacing: 20) {
                // Top Settings Bar
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Domain Input
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(AppTheme.neonCyan)
                            TextField("Domain", text: $domain)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding(10)
                        .background(AppTheme.bgDark.opacity(0.8))
                        .cornerRadius(8)
                        
                        // Record Type
                        Picker("", selection: $selectedType) {
                            ForEach(DNSRecordType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                        .background(AppTheme.bgDark.opacity(0.8))
                        .cornerRadius(8)
                    }
                    
                    HStack(spacing: 12) {
                        // DNS Server Input
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundStyle(AppTheme.neonCyan)
                            TextField("DNS Server (Optional)", text: $dnsServer)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding(10)
                        .background(AppTheme.bgDark.opacity(0.8))
                        .cornerRadius(8)
                        
                        // Short Toggle
                        Toggle("Short", isOn: $useShortOutput)
                            .toggleStyle(.button)
                            .tint(AppTheme.neonCyan)
                            .controlSize(.small)
                        
                        // Action Button
                        Button(action: {
                            if service.isRunning {
                                service.stop()
                            } else {
                                service.lookup(domain: domain, type: selectedType, server: dnsServer, short: useShortOutput)
                            }
                        }) {
                            if service.isRunning {
                                HStack {
                                    ProgressView().controlSize(.small).brightness(1)
                                    Text("STOP")
                                }
                            } else {
                                Text("LOOKUP")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(service.isRunning ? AppTheme.neonRed : AppTheme.neonCyan)
                        .frame(width: 100)
                    }
                }
                
                // Terminal Output
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("TERMINAL OUTPUT")
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Button(action: { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(service.output, forType: .string) }) {
                            Image(systemName: "doc.on.doc")
                                .font(.body)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.bgDark)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border.opacity(0.5), lineWidth: 1))
                        
                        ScrollView {
                            Text(service.output)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(AppTheme.neonGreen)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(minHeight: 300, maxHeight: 600)
                }
            }
            .padding(.vertical, 10)
        }
    }
}
