
import Foundation
import Combine

class PingService: ObservableObject {
    @Published var isPinging = false // Optional state if needed locally
    
    // Pass logs back via closure or Combine subject. Using closure for simplicity in service.
    var onLog: ((LogEntry) -> Void)?
    
    private var pingProcess: Process?
    private var pingPipe: Pipe?
    
    func startPing(host: String, interval: Double = 1.0) {
        stopPing()
        
        guard !host.isEmpty else {
            onLog?(LogEntry(message: "Error: Hostname cannot be empty.", type: .error))
            return
        }
        
        isPinging = true
        onLog?(LogEntry(message: "Starting ping to \(host) every \(interval)s...", type: .info))
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-i", String(format: "%.1f", interval), host]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        self.pingProcess = process
        self.pingPipe = pipe
        
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { [weak self] pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8), !line.isEmpty {
                if line.contains("Operation not permitted") {
                    self?.stopPing()
                    self?.onLog?(LogEntry(message: "Ping stopped: Operation not permitted. Please enable App Sandbox > Outgoing Connections in Xcode.", type: .error))
                    return
                }
                
                let type: LogType = line.contains("timeout") || line.contains("error") || line.contains("Unknown") ? .error : .success
                let cleanLines = line.split(separator: "\n")
                
                DispatchQueue.main.async {
                    for cleanLine in cleanLines {
                        self?.onLog?(LogEntry(message: String(cleanLine), type: type))
                    }
                }
            }
        }
        
        do {
            try process.run()
        } catch {
            onLog?(LogEntry(message: "Failed to start ping: \(error.localizedDescription)", type: .error))
            isPinging = false
        }
    }
    
    func stopPing() {
        if let process = pingProcess, process.isRunning {
            process.terminate()
            onLog?(LogEntry(message: "Ping stopped.", type: .info))
        }
        pingProcess = nil
        pingPipe = nil
        isPinging = false
    }
}
