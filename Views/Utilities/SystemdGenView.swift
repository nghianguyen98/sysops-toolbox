import SwiftUI
import Combine

class SystemdViewModel: ObservableObject {
    @Published var serviceName: String = "My Application"
    @Published var execStart: String = "/usr/bin/python3 /opt/app/main.py"
    @Published var user: String = "root"
    @Published var group: String = "root"
    @Published var workDir: String = "/opt/app"
    @Published var autoRestart: Bool = true
    @Published var restartSec: Int = 5
    @Published var envVars: String = "PORT=8080\nLOG_LEVEL=info"
    
    var generatedContent: String {
        var content = """
        [Unit]
        Description=\(serviceName)
        After=network.target
        
        [Service]
        ExecStart=\(execStart)
        WorkingDirectory=\(workDir)
        User=\(user)
        Group=\(group)
        """
        
        if autoRestart {
            content += "\nRestart=always"
            content += "\nRestartSec=\(restartSec)"
        }
        
        let envs = envVars.split(separator: "\n")
        for env in envs {
            if !env.trimmingCharacters(in: .whitespaces).isEmpty {
                content += "\nEnvironment=\(env.trimmingCharacters(in: .whitespaces))"
            }
        }
        
        content += """
        
        
        [Install]
        WantedBy=multi-user.target
        """
        
        return content
    }
}

struct SystemdGenView: View {
    @StateObject private var viewModel = SystemdViewModel()
    @State private var copied: Bool = false
    
    var body: some View {
        ToolCard(title: "Systemd Unit Generator", icon: "gearshape.2") {
            HStack(spacing: 0) {
                // LEFT: Config Form
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Section: Unit Info
                            Group {
                                Text("Unit Information")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.neonCyan)
                                
                                InputField(label: "Description", text: $viewModel.serviceName)
                                InputField(label: "Command (ExecStart)", text: $viewModel.execStart)
                                InputField(label: "Working Directory", text: $viewModel.workDir)
                            }
                            
                            Divider().background(AppTheme.border)
                            
                            // Section: Execution Context
                            Group {
                                Text("Execution Context")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.neonCyan)
                                
                                HStack(spacing: 16) {
                                    InputField(label: "User", text: $viewModel.user)
                                    InputField(label: "Group", text: $viewModel.group)
                                }
                                
                                Toggle(isOn: $viewModel.autoRestart) {
                                    VStack(alignment: .leading) {
                                        Text("Auto-Restart")
                                            .font(.body)
                                            .foregroundStyle(AppTheme.textPrimary)
                                        Text("Restart=always")
                                            .font(.body)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                .toggleStyle(.switch)
                                .padding(.vertical, 4)
                                
                                if viewModel.autoRestart {
                                    HStack {
                                        Text("Restart Delay (sec):")
                                            .foregroundStyle(AppTheme.textPrimary)
                                        TextField("Seconds", value: $viewModel.restartSec, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 60)
                                    }
                                }
                            }
                            
                            Divider().background(AppTheme.border)
                            
                            // Section: Environment
                            Group {
                                Text("Environment Variables")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.neonCyan)
                                
                                Text("One KEY=VALUE per line")
                                    .font(.callout)
                                    .foregroundStyle(AppTheme.textSecondary)
                                
                                TextEditor(text: $viewModel.envVars)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .background(AppTheme.bgDark.opacity(0.5))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border))
                            }
                        }
                        .padding()
                    }
                }
                .frame(width: 400) // Fixed width for config side
                
                Divider()
                    .background(AppTheme.border)
                
                // RIGHT: Preview
                VStack(spacing: 0) {
                    HStack {
                        Text("PREVIEW")
                            .font(.callout.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(viewModel.generatedContent, forType: .string)
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied" : "Copy Content")
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
                    .padding()
                    .background(AppTheme.bgDark)
                    
                    Divider().background(AppTheme.border)
                    
                    ScrollView {
                        Text(viewModel.generatedContent)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(AppTheme.neonGreen) // Matrix/Terminal style
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.black.opacity(0.5))
                }
            }
            .frame(height: 600) // Explicit height to prevent collapse
        }
    }
}

// Reusable Input Field
struct InputField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.callout)
                .foregroundStyle(AppTheme.textSecondary)
            
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .padding(10)
                .background(AppTheme.bgDark.opacity(0.5))
                .cornerRadius(8)
                .foregroundStyle(AppTheme.textPrimary)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border.opacity(0.5)))
        }
    }
}
