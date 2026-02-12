import Foundation
import Combine

enum DNSRecordType: String, CaseIterable, Identifiable {
    case A, AAAA, CNAME, MX, NS, TXT, SOA, PTR
    var id: String { self.rawValue }
}

class DNSLookupService: ObservableObject {
    @Published var output: String = ""
    @Published var isRunning: Bool = false
    
    private var process: Process?
    
    func lookup(domain: String, type: DNSRecordType, server: String = "", short: Bool = false) {
        guard !domain.isEmpty else { return }
        
        isRunning = true
        output = "Searching DNS records for \(domain)...\n"
        
        var arguments: [String] = []
        
        // Custom DNS Server
        if !server.isEmpty {
            let cleanServer = server.trimmingCharacters(in: .whitespaces)
            arguments.append("@\(cleanServer)")
        }
        
        arguments.append(domain)
        arguments.append(type.rawValue)
        
        if short {
            arguments.append("+short")
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/dig")
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        process = task
        
        task.terminationHandler = { [weak self] _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.output = result.isEmpty ? "No records found." : result
                    self?.isRunning = false
                }
            }
        }
        
        do {
            try task.run()
        } catch {
            output = "Error: \(error.localizedDescription)"
            isRunning = false
        }
    }
    
    func stop() {
        process?.terminate()
        process = nil
        isRunning = false
    }
}
