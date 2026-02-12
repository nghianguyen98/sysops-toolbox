import SwiftUI
import Combine

struct PermissionGroup {
    var read: Bool = false
    var write: Bool = false
    var execute: Bool = false
    
    var value: Int {
        (read ? 4 : 0) + (write ? 2 : 0) + (execute ? 1 : 0)
    }
    
    var string: String {
        (read ? "r" : "-") + (write ? "w" : "-") + (execute ? "x" : "-")
    }
}

class ChmodViewModel: ObservableObject {
    @Published var owner = PermissionGroup()
    @Published var group = PermissionGroup()
    @Published var publicGroup = PermissionGroup()
    
    @Published var octalCode: String = "000"
    
    private var subscribers = Set<AnyCancellable>()
    private var isUpdatingFromText = false
    
    init() {
        // Observe owner, group, public
        Publishers.CombineLatest3($owner, $group, $publicGroup)
            .map { owner, group, pub in
                "\(owner.value)\(group.value)\(pub.value)"
            }
            .sink { [weak self] newCode in
                guard let self = self, !self.isUpdatingFromText else { return }
                if self.octalCode != newCode {
                    self.octalCode = newCode
                }
            }
            .store(in: &subscribers)
        
        // Defaults
        updateFromOctal("755")
    }
    
    func updateFromOctal(_ code: String) {
        guard code.count == 3 else { return }
        isUpdatingFromText = true
        
        let digits = Array(code).compactMap { Int(String($0)) }
        guard digits.count == 3 else {
            isUpdatingFromText = false
            return
        }
        
        owner = groupFromInt(digits[0])
        group = groupFromInt(digits[1])
        publicGroup = groupFromInt(digits[2])
        
        octalCode = code
        isUpdatingFromText = false
    }
    
    private func groupFromInt(_ val: Int) -> PermissionGroup {
        var g = PermissionGroup()
        // 4+2+1 = 7
        g.read = (val & 4) != 0
        g.write = (val & 2) != 0
        g.execute = (val & 1) != 0
        return g
    }
    
    var symbolicString: String {
        "-\(owner.string)\(group.string)\(publicGroup.string)"
    }
}

struct ChmodCalcView: View {
    @StateObject private var viewModel = ChmodViewModel()
    @State private var copied: Bool = false
    
    var body: some View {
        ToolCard(title: "Chmod Calculator", icon: "lock.shield") {
            VStack(spacing: 30) {
                // Result Display
                HStack(spacing: 20) {
                    // Octal
                    VStack(spacing: 5) {
                        Text("OCTAL")
                            .font(.callout)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("755", text: Binding(
                            get: { viewModel.octalCode },
                            set: { viewModel.updateFromOctal($0) }
                        ))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.neonCyan)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(AppTheme.bgDark.opacity(0.5))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.neonCyan.opacity(0.3)))
                    }
                    
                    // Division
                    Text("/")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    // Symbolic
                    VStack(spacing: 5) {
                        Text("SYMBOLIC")
                            .font(.callout)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(viewModel.symbolicString)
                            .font(.system(size: 24, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .background(AppTheme.bgDark.opacity(0.5))
                            .cornerRadius(12)
                    }
                }
                
                // Copy Button
                Button(action: {
                    let content = "chmod \(viewModel.octalCode) file"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                }) {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied Command!" : "Copy 'chmod \(viewModel.octalCode) ...'")
                    }
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: 300)
                    .background(copied ? AppTheme.neonGreen.opacity(0.2) : AppTheme.bgDark)
                    .foregroundStyle(copied ? AppTheme.neonGreen : AppTheme.neonCyan)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(copied ? AppTheme.neonGreen : AppTheme.neonCyan, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Divider()
                    .background(AppTheme.border)
                
                // Matrix Grid
                HStack(spacing: 40) {
                    PermissionColumn(title: "Owner", group: $viewModel.owner)
                    PermissionColumn(title: "Group", group: $viewModel.group)
                    PermissionColumn(title: "Public", group: $viewModel.publicGroup)
                }
            }
            .padding()
        }
    }
}

struct PermissionColumn: View {
    let title: String
    @Binding var group: PermissionGroup
    
    var body: some View {
        VStack(spacing: 15) {
            Text(title.uppercased())
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $group.read) {
                    Text("Read (4)")
                        .font(.system(.body, design: .monospaced))
                }
                .toggleStyle(CheckboxToggleStyle())
                
                Toggle(isOn: $group.write) {
                    Text("Write (2)")
                        .font(.system(.body, design: .monospaced))
                }
                .toggleStyle(CheckboxToggleStyle())
                
                Toggle(isOn: $group.execute) {
                    Text("Exec (1)")
                        .font(.system(.body, design: .monospaced))
                }
                .toggleStyle(CheckboxToggleStyle())
            }
        }
        .frame(width: 120)
        .padding()
        .background(AppTheme.bgCard.opacity(0.5))
        .cornerRadius(12)
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundStyle(configuration.isOn ? AppTheme.neonCyan : AppTheme.textSecondary)
                .font(.system(size: 20))
                .onTapGesture { configuration.isOn.toggle() }
            
            configuration.label
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}
