import SwiftUI

struct SSLInspectorView: View {
    @StateObject private var service = SSLInspectorService()
    @State private var domain = "google.com"
    
    var body: some View {
        ToolCard(title: "SSL Certificate Inspector", icon: "checkmark.shield.fill") {
            VStack(spacing: 24) {
                // Input Section
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(AppTheme.neonCyan)
                        TextField("Enter Domain (e.g. google.com)", text: $domain)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(12)
                    .background(AppTheme.bgDark.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.neonCyan.opacity(0.3), lineWidth: 1))
                    
                    if service.isChecking {
                        Button(action: {
                            service.stopCheck()
                        }) {
                            HStack {
                                ProgressView().controlSize(.small)
                                    .brightness(1)
                                Text("ABORT")
                                    .font(.system(.subheadline, design: .monospaced).bold())
                            }
                        }
                        .frame(width: 120, height: 44)
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.neonRed)
                    } else {
                        Button(action: {
                            service.checkSSL(domain: domain)
                        }) {
                            Text("INSPECT")
                                .font(.system(.subheadline, design: .monospaced).bold())
                        }
                        .frame(width: 120, height: 44)
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.neonCyan)
                        .disabled(domain.isEmpty)
                    }
                }
                
                if let error = service.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                            .font(.system(.body, design: .monospaced))
                    }
                    .foregroundStyle(AppTheme.neonRed)
                    .padding()
                    .background(AppTheme.neonRed.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let result = service.result {
                    VStack(spacing: 24) {
                        // Big Status Indicator
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(statusColor(result.status).opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: statusIcon(result.status))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(statusColor(result.status))
                            }
                            
                            VStack(spacing: 4) {
                                Text(result.status == .valid ? "CERTIFICATE VALID" : result.status == .warning ? "EXPIRES SOON" : "CERTIFICATE EXPIRED")
                                    .font(.system(.headline, design: .monospaced).bold())
                                    .foregroundStyle(statusColor(result.status))
                                
                                Text("\(result.daysRemaining) Days Remaining")
                                    .font(.system(.title2, design: .monospaced).bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // Details Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("DOMAIN DETAILS")
                                    .font(.system(.subheadline, design: .monospaced).bold())
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                if result.isSelfSigned {
                                    Text("SELF-SIGNED")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.neonOrange.opacity(0.2))
                                        .foregroundStyle(AppTheme.neonOrange)
                                        .cornerRadius(4)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                DetailRow(label: "Issued To", value: result.commonName)
                                Divider().background(AppTheme.border.opacity(0.2))
                                DetailRow(label: "Issuer", value: result.issuer)
                                Divider().background(AppTheme.border.opacity(0.2))
                                DetailRow(label: "Valid From", value: formatDate(result.validFrom))
                                Divider().background(AppTheme.border.opacity(0.2))
                                DetailRow(label: "Valid Until", value: formatDate(result.validTo))
                            }
                        }
                        .padding(20)
                        .background(AppTheme.bgDark.opacity(0.3))
                        .cornerRadius(12)
                    }
                } else if !service.isChecking {
                    ContentUnavailableView {
                        Label("Ready to Inspect", systemImage: "shield.lefthalf.filled")
                            .font(.largeTitle)
                    } description: {
                        Text("Verify SSL protocols and expiration dates for any domain.")
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    private func statusColor(_ status: SSLStatus) -> Color {
        switch status {
        case .valid: return AppTheme.neonGreen
        case .warning: return AppTheme.neonOrange
        case .expired: return AppTheme.neonRed
        }
    }
    
    private func statusIcon(_ status: SSLStatus) -> String {
        switch status {
        case .valid: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .expired: return "xmark.shield.fill"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
        }
    }
}
