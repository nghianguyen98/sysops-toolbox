import Foundation
import Combine

struct TracerouteHop: Identifiable {
    let id = UUID()
    let number: Int
    let hostname: String
    let ip: String
    let latency: Double?
    let status: HopStatus
    
    enum HopStatus {
        case success
        case timeout
        case running
    }
}

class TracerouteService: ObservableObject {
    @Published var hops: [TracerouteHop] = []
    @Published var isRunning: Bool = false
    
    private var currentTask: Process?
    private var cancellables = Set<AnyCancellable>()
    var onLog: ((LogEntry) -> Void)?
    
    func startTrace(host: String) {
        guard !isRunning else { return }
        isRunning = true
        hops = []
        
        onLog?(LogEntry(message: "Starting Sandbox-friendly traceroute to \(host)...", type: .info))
        
        // We run pings sequentially for each TTL from 1 to 30
        runNextHop(host: host, ttl: 1)
    }
    
    func stopTrace() {
        currentTask?.terminate()
        currentTask = nil
        isRunning = false
    }
    
    private var hopStartTime: Date?
    
    private func runNextHop(host: String, ttl: Int) {
        guard isRunning && ttl <= 30 else {
            finishTrace()
            return
        }
        
        // Add a "running" placeholder hop
        DispatchQueue.main.async {
            self.hops.append(TracerouteHop(number: ttl, hostname: "Searching...", ip: "", latency: nil, status: .running))
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/sbin/ping")
        task.arguments = ["-c", "1", "-m", "\(ttl)", "-t", "2", host]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        currentTask = task
        
        self.hopStartTime = Date() // Mark start time
        
        task.terminationHandler = { [weak self] _ in
            let duration = Date().timeIntervalSince(self?.hopStartTime ?? Date()) * 1000.0 // Duration in ms
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                self?.handlePingOutput(output, ttl: ttl, host: host, manualLatency: duration)
            }
        }
        
        do {
            try task.run()
        } catch {
            onLog?(LogEntry(message: "Ping failed at hop \(ttl): \(error.localizedDescription)", type: .error))
            finishTrace()
        }
    }
    
    private func handlePingOutput(_ output: String, ttl: Int, host: String, manualLatency: Double) {
        var foundHop: TracerouteHop?
        var reachedDestination = false
        
        onLog?(LogEntry(message: "RAW TTL \(ttl): \(output.replacingOccurrences(of: "\n", with: " "))", type: .debug))
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("Time to live exceeded") {
                let ip = extractIP(from: line)
                foundHop = TracerouteHop(number: ttl, hostname: ip, ip: ip, latency: manualLatency, status: .success)
            } else if line.contains("bytes from") {
                let ip = extractIP(from: line)
                foundHop = TracerouteHop(number: ttl, hostname: ip, ip: ip, latency: manualLatency, status: .success)
                // Only mark as reached if it's actually responding to the probe, 
                // and the output isn't a "Time to live exceeded" from another host.
                reachedDestination = true
            }
        }
        
        if foundHop == nil {
            foundHop = TracerouteHop(number: ttl, hostname: "*", ip: "*", latency: nil, status: .timeout)
        }
        
        DispatchQueue.main.async {
            guard self.isRunning else { return }
            
            // Replace the "running" placeholder
            if let index = self.hops.firstIndex(where: { $0.number == ttl }) {
                self.hops[index] = foundHop!
            }
            
            if reachedDestination {
                self.finishTrace()
            } else {
                self.runNextHop(host: host, ttl: ttl + 1)
            }
        }
    }
    
    private func extractIP(from line: String) -> String {
        // Try regex first for precision
        if let range = line.range(of: "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}", options: .regularExpression) {
            return String(line[range])
        }
        
        // Fallback to parts
        let parts = line.components(separatedBy: CharacterSet(charactersIn: " :()"))
        for (index, part) in parts.enumerated() {
            if (part.lowercased() == "from" || part.lowercased() == "bytes") && index + 1 < parts.count {
                let next = parts[index + 1]
                if next.contains(".") { return next }
                if index + 2 < parts.count && parts[index + 2].contains(".") { return parts[index + 2] }
            }
        }
        return "Unknown"
    }
    
    private func extractLatency(from line: String) -> Double? {
        if let range = line.range(of: "time=") {
            let suffix = line[range.upperBound...]
            let parts = suffix.components(separatedBy: " ")
            if let first = parts.first, let val = Double(first) {
                return val
            }
        }
        return nil
    }
    
    private func finishTrace() {
        DispatchQueue.main.async {
            self.isRunning = false
            self.onLog?(LogEntry(message: "Traceroute completed.", type: .info))
        }
    }
}
