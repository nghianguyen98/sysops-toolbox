import SwiftUI

struct WhoisLookupView: View {
    @StateObject private var service = WhoisService()
    @State private var domain = ""
    
    var body: some View {
        ToolCard(title: "Whois Lookup", icon: "person.text.rectangle.fill") {
            VStack(spacing: 20) {
                // Input Section
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(AppTheme.neonCyan)
                        TextField("Enter Domain (e.g. google.com)", text: $domain)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .onSubmit {
                                service.lookup(domain: domain)
                            }
                    }
                    .padding(12)
                    .background(AppTheme.bgDark.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.neonCyan.opacity(0.3), lineWidth: 1))
                    
                    Button(action: {
                        if service.isRunning {
                            service.stop()
                        } else {
                            service.lookup(domain: domain)
                        }
                    }) {
                        if service.isRunning {
                            HStack {
                                ProgressView().controlSize(.small).brightness(1)
                                Text("ABORT")
                            }
                        } else {
                            Text("QUERY")
                        }
                    }
                    .frame(width: 100, height: 44)
                    .buttonStyle(.borderedProminent)
                    .tint(service.isRunning ? AppTheme.neonRed : AppTheme.neonCyan)
                    .disabled(domain.isEmpty && !service.isRunning)
                }
                
                if let error = service.errorMessage {
                    Text(error)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(AppTheme.neonRed)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.neonRed.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if let summary = service.summary {
                    VStack(spacing: 16) {
                        // Quick Status Card
                        HStack(spacing: 20) {
                            StatusOrb(title: "DOMAIN", value: summary.domain.uppercased(), color: AppTheme.neonCyan)
                            StatusOrb(title: "RESOLVED IP", value: summary.resolvedIPs.first ?? "N/A", color: AppTheme.neonGreen)
                        }
                        
                        // Details Grid
                        VStack(spacing: 0) {
                            SummaryRow(label: "REGISTRAR", value: summary.registrar)
                            Divider().background(AppTheme.border.opacity(0.3))
                            SummaryRow(label: "EXPIRY DATE", value: summary.expiryDate, valueColor: AppTheme.neonOrange)
                            Divider().background(AppTheme.border.opacity(0.3))
                            SummaryRow(label: "NAME SERVERS", value: summary.nameServers.joined(separator: ", "))
                        }
                        .background(AppTheme.bgDark.opacity(0.5))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border.opacity(0.5), lineWidth: 1))
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Advanced Terminal Output (Collapsible)
                DisclosureGroup("Raw Whois Output") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(service.output.components(separatedBy: .newlines), id: \.self) { line in
                                Text(line)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary.opacity(0.7))
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 200)
                    .background(AppTheme.bgDark)
                    .cornerRadius(8)
                }
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundStyle(AppTheme.textSecondary)
                .accentColor(AppTheme.neonCyan)
            }
            .padding(.vertical, 10)
        }
    }
}

struct StatusOrb: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(.footnote, design: .monospaced).bold())
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.system(.headline, design: .monospaced).bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    var valueColor: Color = AppTheme.textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.footnote, design: .monospaced).bold())
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(valueColor)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

