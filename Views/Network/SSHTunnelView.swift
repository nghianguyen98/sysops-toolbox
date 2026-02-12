import SwiftUI
import Combine

class SSHTunnelViewModel: ObservableObject {
    @Published var localPort: String = "3306"
    @Published var jumpUser: String = "root"
    @Published var jumpHost: String = "bastion.example.com"
    @Published var destHost: String = "db-internal"
    @Published var destPort: String = "3306"
    
    var generatedCommand: String {
        // ssh -L {LocalPort}:{DestHost}:{DestPort} {JumpUser}@{JumpHost} -N
        let userPart = jumpUser.isEmpty ? "" : "\(jumpUser)@"
        return "ssh -L \(localPort):\(destHost):\(destPort) \(userPart)\(jumpHost) -N"
    }
}

struct SSHTunnelView: View {
    @StateObject private var viewModel = SSHTunnelViewModel()
    @State private var copied: Bool = false
    
    var body: some View {
        ToolCard(title: "SSH Tunnel Builder", icon: "network.badge.shield.half.filled") {
            VStack(spacing: 30) {
                // Header / Intro
                Text("Visualize and generate Local Port Forwarding commands.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // DIAGRAM SECTION
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        // 1. My Mac
                        NodeCard(title: "My Mac (Local)", icon: "laptopcomputer") {
                            VStack(alignment: .leading) {
                                Text("Listening Port")
                                    .font(.callout)
                                    .foregroundStyle(AppTheme.textSecondary)
                                TextField("Port", text: $viewModel.localPort)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                        }
                        
                        // Arrow
                        ArrowView()
                        
                        // 2. Jump Host
                        NodeCard(title: "SSH Jump Host", icon: "server.rack") {
                            VStack(alignment: .leading, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SSH User")
                                        .font(.callout)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    TextField("User", text: $viewModel.jumpUser)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SSH Host/IP")
                                        .font(.callout)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    TextField("Host", text: $viewModel.jumpHost)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            .frame(width: 140)
                        }
                        
                        // Arrow
                        ArrowView()
                        
                        // 3. Target
                        NodeCard(title: "Target Service", icon: "cylinder.split.1x2") {
                             VStack(alignment: .leading, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Destination Host")
                                        .font(.callout)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    TextField("Host", text: $viewModel.destHost)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Destination Port")
                                        .font(.callout)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    TextField("Port", text: $viewModel.destPort)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                            }
                            .frame(width: 140)
                        }
                    }
                    .padding()
                }
                .background(AppTheme.bgDark.opacity(0.3))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border.opacity(0.5)))
                
                // COMMAND SECTION
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("GENERATED COMMAND")
                            .font(.body.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(viewModel.generatedCommand, forType: .string)
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied" : "Copy Command")
                            }

                            .font(.body.bold())
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(copied ? AppTheme.neonGreen.opacity(0.2) : AppTheme.bgCard)
                            .foregroundStyle(copied ? AppTheme.neonGreen : AppTheme.neonCyan)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(copied ? AppTheme.neonGreen.opacity(0.5) : AppTheme.neonCyan.opacity(0.3)))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(viewModel.generatedCommand)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(AppTheme.neonGreen)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border))
                        .textSelection(.enabled)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// Helper Components
struct NodeCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.neonCyan)
                Text(title)
                    .font(.title3)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Divider().background(AppTheme.border)
            content
        }
        .padding()
        .background(AppTheme.bgCard)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border))
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct ArrowView: View {
    var body: some View {
        VStack {
            Image(systemName: "arrow.right")
                .font(.title2)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("SSH Tunnel")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
        }
    }
}
