
import SwiftUI
import Combine

class DockerConverterViewModel: ObservableObject {
    @Published var inputCommand: String = ""
    @Published var outputYaml: String = ""
    @Published var isConverting: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $inputCommand
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] cmd in
                self?.convert(cmd)
            }
            .store(in: &cancellables)
    }
    
    func convert(_ command: String) {
        guard !command.isEmpty else {
            outputYaml = ""
            return
        }
        
        isConverting = true
        
        // Simulate slight delay for "processing" feel
        DispatchQueue.global(qos: .userInitiated).async {
            // Pre-process: Handle backslash line continuations
            let multilineFixed = command.replacingOccurrences(of: "\\\n", with: " ")
                                        .replacingOccurrences(of: "\\", with: " ")
                                        .replacingOccurrences(of: "\n", with: " ")
            
            let cleaned = multilineFixed.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Basic validation
            var result = ""
            if !cleaned.isEmpty && !cleaned.contains("docker") {
                result = "# Note: Command doesn't look like 'docker run'. Attempting parse anyway...\n"
            }
            
            let parser = DockerRunParser(command: cleaned)
            let service = parser.parse()
            result += service.toYaml()
            
            DispatchQueue.main.async {
                self.outputYaml = result
                self.isConverting = false
            }
        }
    }
}

struct DockerConverterView: View {
    @StateObject private var viewModel = DockerConverterViewModel()
    @State private var isCopied: Bool = false
    
    var body: some View {
        ToolCard(title: "Compose Builder", icon: "shippingbox.fill") {
            VStack(spacing: 24) {
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("DOCKER RUN COMMAND", systemImage: "terminal")
                        .font(.callout.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.inputCommand.isEmpty {
                            Text("Paste 'docker run' command here...")
                                .font(.body)
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                                .padding(16)
                        }
                        
                        TextEditor(text: $viewModel.inputCommand)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                            .scrollContentBackground(.hidden) // Remove default background
                            .padding(12)
                    }
                    .frame(minHeight: 120)
                    .background(AppTheme.bgDark)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.border.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Direction Indicator
                HStack {
                    Divider()
                        .frame(width: 40)
                        .background(AppTheme.border)
                    
                    ZStack {
                        Circle()
                            .fill(AppTheme.bgSecondary)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(AppTheme.border.opacity(0.5)))
                        
                        Image(systemName: "arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    if viewModel.isConverting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .padding(.leading, 8)
                    }
                    
                    Divider()
                        .frame(width: 40) // Fixed width
                        .background(AppTheme.border)
                }
                .padding(.vertical, 4)
                
                // Output Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("DOCKER COMPOSE (YAML)", systemImage: "doc.text")
                            .font(.callout.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Spacer()
                        
                        if !viewModel.outputYaml.isEmpty {
                            Button(action: copyToClipboard) {
                                HStack(spacing: 6) {
                                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    Text(isCopied ? "Copied" : "Copy")
                                }
                                .font(.system(.body, design: .monospaced).bold())
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(isCopied ? AppTheme.neonGreen.opacity(0.2) : AppTheme.bgSecondary)
                                .foregroundStyle(isCopied ? AppTheme.neonGreen : AppTheme.neonCyan)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    ScrollView {
                        Text(viewModel.outputYaml.isEmpty ? "# Waiting for input..." : viewModel.outputYaml)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(viewModel.outputYaml.isEmpty ? AppTheme.textSecondary.opacity(0.5) : AppTheme.neonGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                    }
                    .frame(minHeight: 200)
                    .background(AppTheme.bgDark)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.border.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(viewModel.outputYaml, forType: .string)
        withAnimation { isCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isCopied = false }
        }
    }
}

// MARK: - Logic (Parser)

struct DockerService {
    var imageName: String = ""
    var containerName: String?
    var ports: [String] = []
    var volumes: [String] = []
    var environment: [String] = []
    var restart: String?
    var networks: [String] = []
    
    func toYaml() -> String {
        var yaml = "version: '3.8'\nservices:\n"
        let serviceName = containerName ?? "app"
        yaml += "  \(serviceName):\n"
        yaml += "    image: \(imageName)\n"
        
        if let name = containerName {
            yaml += "    container_name: \(name)\n"
        }
        
        if let restart = restart {
            yaml += "    restart: \(restart)\n"
        }
        
        if !ports.isEmpty {
            yaml += "    ports:\n"
            for p in ports {
                yaml += "      - \"\(p)\"\n"
            }
        }
        
        if !volumes.isEmpty {
            yaml += "    volumes:\n"
            for v in volumes {
                yaml += "      - \"\(v)\"\n"
            }
        }
        
        if !environment.isEmpty {
            yaml += "    environment:\n"
            for e in environment {
                yaml += "      - \(e)\n"
            }
        }
        
        if !networks.isEmpty {
             yaml += "    networks:\n"
             for n in networks {
                 yaml += "      - \(n)\n"
             }
        }
        
        return yaml
    }
}

struct DockerRunParser {
    let command: String
    
    init(command: String) {
        self.command = command
    }
    
    func parse() -> DockerService {
        var service = DockerService()
        
        // Simple tokenization (imperfect for complex quoting)
        let args = splitArgs(command)
        var i = 0
        
        while i < args.count {
            let arg = args[i]
            checkFlag(arg, args: args, index: &i, service: &service)
            i += 1
        }
        
        // Find image name (last non-flag arg usually)
        let leftover = args.enumerated().filter { idx, val in
            !val.hasPrefix("-") && val != "docker" && val != "run" && !consumedIndices.contains(idx)
        }.map { $0.element }
        
        service.imageName = leftover.last ?? "unknown-image" // Prefer last arg as image
        
        return service
    }
    
    // Internal State
    private class Box { var indices: Set<Int> = [] }
    private var consumedBox = Box()
    private var consumedIndices: Set<Int> { consumedBox.indices }
    
    private func checkFlag(_ arg: String, args: [String], index: inout Int, service: inout DockerService) {
        func nextValue() -> String? {
            if index + 1 < args.count {
                consumedBox.indices.insert(index + 1)
                return args[index + 1]
            }
            return nil
        }
        
        switch arg {
        case "-p", "--publish":
            if let val = nextValue() { service.ports.append(val) }
        case "-v", "--volume":
            if let val = nextValue() { service.volumes.append(val) }
        case "-e", "--env":
            if let val = nextValue() { service.environment.append(val) }
        case "--name":
            if let val = nextValue() { service.containerName = val }
        case "--restart":
            if let val = nextValue() { service.restart = val }
        case "--net", "--network":
            if let val = nextValue() { service.networks.append(val) }
        default:
            break
        }
    }
    
    private func splitArgs(_ cmd: String) -> [String] {
        return cmd.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }
}
