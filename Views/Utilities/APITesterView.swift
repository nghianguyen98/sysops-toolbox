import SwiftUI

struct RequestHeader: Identifiable {
    let id = UUID()
    var key: String
    var value: String
}

struct APITesterView: View {
    @StateObject private var service = APITesterService()
    
    // Input State
    @State private var url: String = "https://jsonplaceholder.typicode.com/todos/1"
    @State private var method: String = "GET" // Using String to match picker easily, or map to enum
    @State private var selectedMethod: HTTPMethod = .get
    @State private var headers: [RequestHeader] = [RequestHeader(key: "Content-Type", value: "application/json")]
    @State private var requestBody: String = ""
    @State private var selectedTab: String = "Headers"
    
    // cURL Import State
    @State private var showCurlImport = false
    @State private var curlCommand = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ToolCard(title: "API Tester", icon: "antenna.radiowaves.left.and.right") {
            VStack(spacing: 16) {
                // Top Bar: Method + URL + Send
                HStack(spacing: 10) {
                    Picker("", selection: $selectedMethod) {
                        ForEach(HTTPMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .frame(width: 100)
                    .labelsHidden()
                    
                    TextField("https://api.example.com/v1/resource", text: $url)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(AppTheme.bgDark.opacity(0.8))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
                        .font(.system(.body, design: .monospaced))
                    
                    // Import Button
                    Button(action: { showCurlImport = true }) {
                        Image(systemName: "arrow.down.doc")
                    }
                    .buttonStyle(.plain)
                    .help("Import from cURL")
                    
                    Button(action: sendRequest) {
                        if service.isRequesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("SEND")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.neonCyan)
                    .disabled(service.isRequesting || url.isEmpty)
                }
                
                // Config Area (Tabs)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 20) {
                        tabButton("Headers", selection: $selectedTab)
                        tabButton("Body", selection: $selectedTab)
                    }
                    .padding(.bottom, 8)
                    
                    Divider().background(AppTheme.border)
                    
                    if selectedTab == "Headers" {
                        headersView
                            .frame(height: 150)
                    } else {
                        TextEditor(text: $requestBody)
                            .font(.system(.body, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(AppTheme.bgDark.opacity(0.5))
                            .frame(height: 150)
                    }
                }
                .padding(12)
                .background(AppTheme.bgDark.opacity(0.3))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border.opacity(0.5), lineWidth: 1))
                
                // Response Area
                if let response = service.lastResponse {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("RESPONSE")
                                .font(.callout.bold())
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            // Status Badge
                            Text("\(response.statusCode)")
                                .font(.body.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(for: response.statusCode).opacity(0.2))
                                .foregroundStyle(statusColor(for: response.statusCode))
                                .cornerRadius(4)
                            
                            // Latency Badge
                            Text(String(format: "%.0f ms", response.latency * 1000))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                        Divider().background(AppTheme.border)
                        
                        ScrollView {
                            Text(response.body)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.bgDark)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(statusColor(for: response.statusCode).opacity(0.5), lineWidth: 1))
                    .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showCurlImport) {
            VStack(spacing: 16) {
                Text("Import cURL Command")
                    .font(.headline)
                
                TextEditor(text: $curlCommand)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.bgDark.opacity(0.5))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                    .frame(minHeight: 150)
                
                HStack {
                    Button("Cancel") {
                        showCurlImport = false
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("Import") {
                        parseCurl()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.neonCyan)
                    .disabled(curlCommand.isEmpty)
                }
            }
            .padding()
            .frame(width: 500, height: 300)
            .background(AppTheme.bgDark)
            .alert("Import Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var headersView: some View {
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach($headers) { $header in
                        HStack {
                            TextField("Key", text: $header.key)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(AppTheme.bgDark)
                                .cornerRadius(4)
                            
                            Text(":")
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            TextField("Value", text: $header.value)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(AppTheme.bgDark)
                                .cornerRadius(4)
                            
                            Button(action: {
                                if let index = headers.firstIndex(where: { $0.id == header.id }) {
                                    headers.remove(at: index)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(AppTheme.neonRed)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Button("Add Header") {
                headers.append(RequestHeader(key: "", value: ""))
            }
            .font(.callout)
            .padding(.top, 8)
        }
    }
    
    private func tabButton(_ title: String, selection: Binding<String>) -> some View {
        Button(action: { selection.wrappedValue = title }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(selection.wrappedValue == title ? .bold : .regular)
                .foregroundStyle(selection.wrappedValue == title ? AppTheme.neonCyan : AppTheme.textSecondary)
                .padding(.bottom, 4)
                .overlay(
                    Rectangle()
                        .fill(selection.wrappedValue == title ? AppTheme.neonCyan : Color.clear)
                        .frame(height: 2)
                        .offset(y: 4),
                    alignment: .bottom
                )
        }
        .buttonStyle(.plain)
    }
    
    private func sendRequest() {
        Task {
            var headersDict: [String: String] = [:]
            for h in headers {
                if !h.key.isEmpty {
                    headersDict[h.key] = h.value
                }
            }
            
            await service.sendRequest(url: url, method: selectedMethod, headers: headersDict, body: requestBody)
        }
    }
    
    private func statusColor(for code: Int) -> Color {
        switch code {
        case 200...299: return AppTheme.neonGreen
        case 300...399: return .yellow
        case 400...599: return AppTheme.neonRed
        default: return AppTheme.textSecondary
        }
    }
    
    private func parseCurl() {
        do {
            let request = try CurlParser.parse(curlCommand)
            
            // Populating UI
            self.url = request.url
            self.selectedMethod = request.method
            self.requestBody = request.body ?? ""
            
            // Headers
            self.headers = request.headers.map { RequestHeader(key: $0.key, value: $0.value) }
            
            showCurlImport = false
            curlCommand = "" // Reset
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
}
