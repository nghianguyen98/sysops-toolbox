
import Foundation
import Combine

enum PingStatus {
    case idle
    case active
    case down
}

class PingMonitor: ObservableObject, Identifiable {
    let id = UUID()
    let hostname: String
    
    @Published var status: PingStatus = .idle
    @Published var currentLatency: Double = 0.0
    @Published var history: [Double] = []
    
    private var process: Process?
    private var pipe: Pipe?
    
    init(hostname: String) {
        self.hostname = hostname
    }
    
    func start() {
        guard status != .active else { return }
        stop()
        
        status = .active
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/sbin/ping")
        // -i 1: interval 1 second.
        // --apple-time: prints time in ms? No, standard mac ping output has "time=xx.x ms"
        task.arguments = ["-i", "1", hostname]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        self.process = task
        self.pipe = pipe
        
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let string = String(data: data, encoding: .utf8), !string.isEmpty {
                self?.parseOutput(string)
            }
        }
        
        do {
            try task.run()
        } catch {
            print("Failed to start ping for \(hostname): \(error)")
            DispatchQueue.main.async {
                self.status = .down
            }
        }
    }
    
    func stop() {
        // If process is running, terminate it
        if let process = process, process.isRunning {
             process.terminate()
        }
        process = nil
        pipe = nil
        DispatchQueue.main.async {
            self.status = .idle
        }
    }
    
    private func parseOutput(_ output: String) {
        let lines = output.split(separator: "\n")
        
        for line in lines {
            let lineStr = String(line)
            
            // Check for timeout or error
            if lineStr.contains("timeout") || lineStr.contains("Host is down") || lineStr.contains("Unknown") {
                DispatchQueue.main.async {
                    self.currentLatency = -1 // Indicator for error in graph if needed? Or just ignore
                    self.status = .down
                }
                continue
            }
            
            // Expected format: "64 bytes from ... time=23.4 ms"
            if let timeRange = lineStr.range(of: "time=") {
                let afterTime = lineStr[timeRange.upperBound...]
                // Now we have "23.4 ms..."
                let scanner = Scanner(string: String(afterTime))
                if let latency = scanner.scanDouble() {
                    DispatchQueue.main.async {
                        self.status = .active // Back to active if we get a response
                        self.currentLatency = latency
                        self.addToHistory(latency)
                    }
                }
            }
        }
    }
    
    private func addToHistory(_ value: Double) {
        if history.count >= 300 {
            history.removeFirst()
        }
        history.append(value)
    }
}
