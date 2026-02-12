import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Header Section
                VStack(spacing: 16) {
                    Image("logo") // Uses the AppIcon from Assets
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 128, height: 128)
                        .scaleEffect(1.1)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: AppTheme.neonBlue.opacity(0.3), radius: 20, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    
                    VStack(spacing: 4) {
                        Text("SysOps Toolbox")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.textPrimary, AppTheme.neonBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(AppTheme.bgSecondary)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 40)
                
                // MARK: - Bento Grid Links
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        // Website Card
                        Button(action: { openURL(URL(string: "https://app.sysops.asia")!) }) {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.neonCyan)
                                Text("Website")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Documentation & Guides")
                                    .font(.callout)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(AppTheme.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // GitHub Card
                        Button(action: { openURL(URL(string: "https://github.com/nghianguyen98/sysops-toolbox")!) }) {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.neonPurple)
                                Text("GitHub")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Source Code & Issues")
                                    .font(.callout)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(AppTheme.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // System Status Card
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Image(systemName: "cpu")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundStyle(AppTheme.neonGreen)
                                .padding(8)
                                .background(AppTheme.neonGreen.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("System Info")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(getSystemInfo())
                                    .font(.callout)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            // Status Indicator
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Online")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Divider().background(AppTheme.border)
                        
                        // Hardware Stats
                        HStack(spacing: 24) {
                            HStack {
                                Image(systemName: "memorychip")
                                Text(getRamInfo())
                            }
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal")
                                Text(getCpuInfo())
                            }
                        }
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding()
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    
                    // Feedback & Support (Restored)
                    HStack(spacing: 16) {
                        Image(systemName: "envelope.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(AppTheme.neonPurple) // Changed color to distinguish
                        .padding(8)
                        .background(AppTheme.neonPurple.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Feedback & Support")
                            .font(.title3)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Found a bug? Have a suggestion?")
                            .font(.callout)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { openURL(URL(string: "https://github.com/nghianguyen98/sysops-toolbox/issues")!) }) {
                        Text("Contact Us")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.bgSecondary)
                            .foregroundStyle(AppTheme.textPrimary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            // MARK: - Tech Stack
            VStack(spacing: 12) {
                Text("POWERED BY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.textSecondary)
                    .tracking(2)
                
                HStack(spacing: 20) {
                    TechBadge(icon: "swift", text: "Swift 6.0")
                    TechBadge(icon: "macwindow", text: "SwiftUI")
                }
            }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: 600)
        }
        .background(AppTheme.bgDark.ignoresSafeArea())
    }
    
    // Helper to get system info
    private func getSystemInfo() -> String {
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        var model = "Unknown"
        
        // Use sysctl to get the actual CPU brand string
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        model = String(cString: machine)
        
        // Clean up string if needed
        if model.isEmpty {
            #if arch(arm64)
            model = "Apple Silicon"
            #elseif arch(x86_64)
            model = "Intel"
            #endif
        }
        
        return "macOS \(os) • \(model)"
    }
    
    private func getRamInfo() -> String {
        let memory = ProcessInfo.processInfo.physicalMemory
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memory))
    }
    
    private func getCpuInfo() -> String {
        let cores = ProcessInfo.processInfo.activeProcessorCount
        return "\(cores) Cores"
    }
}

struct TechBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.callout)
        .foregroundStyle(AppTheme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.bgCard)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
    }
}
