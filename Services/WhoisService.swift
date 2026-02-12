import Foundation
import Combine

struct WhoisSummary: Identifiable {
    let id = UUID()
    var domain: String = ""
    var resolvedIPs: [String] = []
    var registrar: String = "Unknown"
    var creationDate: String = "Unknown"
    var expiryDate: String = "Unknown"
    var nameServers: [String] = []
}

class WhoisService: ObservableObject {
    @Published var output: String = ""
    @Published var summary: WhoisSummary?
    @Published var isRunning: Bool = false
    @Published var errorMessage: String?
    
    private var process: Process?
    
    func lookup(domain: String) {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanDomain.isEmpty else { return }
        
        let domainRegex = "^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", domainRegex)
        guard predicate.evaluate(with: cleanDomain) else {
            errorMessage = "Invalid domain format"
            return
        }
        
        isRunning = true
        errorMessage = nil
        output = "Analyzing \(cleanDomain)...\n"
        summary = WhoisSummary(domain: cleanDomain)
        
        // Step 1: Resolve IP using 'host' command
        resolveIP(domain: cleanDomain) { [weak self] ips in
            DispatchQueue.main.async {
                self?.summary?.resolvedIPs = ips
            }
            
            // Step 2: Run WHOIS
            self?.runWhois(domain: cleanDomain)
        }
    }
    
    private func resolveIP(domain: String, completion: @escaping ([String]) -> Void) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/host")
        task.arguments = [domain]
        let pipe = Pipe()
        task.standardOutput = pipe
        
        task.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: data, encoding: .utf8) {
                let ips = self.extractIPs(from: result)
                completion(ips)
            } else {
                completion([])
            }
        }
        
        do { try task.run() } catch { completion([]) }
    }
    
    private func runWhois(domain: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/whois")
        task.arguments = [domain]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        process = task
        
        task.terminationHandler = { [weak self] _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.output = result
                    self?.parseWhois(result)
                    self?.isRunning = false
                }
            }
        }
        
        do { try task.run() } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isRunning = false
            }
        }
    }
    
    private func extractIPs(from text: String) -> [String] {
        let pattern = "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches?.compactMap { match in
            if let range = Range(match.range, in: text) { return String(text[range]) }
            return nil
        } ?? []
    }
    
    private func parseWhois(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
        var ns: [String] = []
        
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("registrar:") && summary?.registrar == "Unknown" {
                summary?.registrar = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
            }
            if (lower.contains("expiry date:") || lower.contains("expiration time:")) && summary?.expiryDate == "Unknown" {
                summary?.expiryDate = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
            }
            if (lower.contains("creation date:") || lower.contains("created on:")) && summary?.creationDate == "Unknown" {
                summary?.creationDate = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
            }
            if lower.contains("name server:") || lower.contains("nserver:") {
                let val = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                if !val.isEmpty { ns.append(val.lowercased()) }
            }
        }
        summary?.nameServers = Array(Set(ns)).sorted()
    }
    
    func stop() {
        process?.terminate()
        process = nil
        isRunning = false
    }
}

