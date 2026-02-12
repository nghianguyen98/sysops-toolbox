
import Foundation
import Network
import Combine



class PortScanService: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0.0
    
    var onLog: ((LogEntry) -> Void)?
    
    private let scanQueue = DispatchQueue(label: "com.nettool.scanQueue", attributes: .concurrent)
    
    // Common Port Map
    private let commonPorts: [Int: String] = [
        // File/Term
        20: "FTP Data", 21: "FTP Control", 22: "SSH", 23: "Telnet", 69: "TFTP",
        // Mail
        25: "SMTP", 110: "POP3", 143: "IMAP", 465: "SMTPS", 587: "SMTP Submission", 993: "IMAPS", 995: "POP3S",
        // Web/Infra
        53: "DNS", 67: "DHCP Server", 68: "DHCP Client", 80: "HTTP", 443: "HTTPS", 8080: "HTTP Alt", 8443: "HTTPS Alt",
        // Database/Cache
        1433: "SQL Server", 3306: "MySQL", 5432: "PostgreSQL", 6379: "Redis", 11211: "Memcached", 27017: "MongoDB", 9200: "Elasticsearch",
        // Remote/VPN
        1194: "OpenVPN", 1723: "PPTP", 3389: "RDP", 5900: "VNC",
        // Directory/Msg
        389: "LDAP", 636: "LDAPS", 1883: "MQTT", 5222: "XMPP",
        // Dev/Gaming
        3000: "React/Node", 3001: "React/Node Alt", 4000: "Elixir/Phoenix", 5000: "Flask/ASP", 8000: "Django/Common",
        25565: "Minecraft", 32400: "Plex"
    ]
    
    func stopScan() {
        isScanning = false
        onLog?(LogEntry(message: "Port scan stopping...", type: .info))
    }
    
    func scanPorts(targetIP: String, startPort: Int, endPort: Int, `protocol`: ScanProtocol = .tcp) {
        guard !isScanning else { return }
        guard startPort <= endPort else {
            onLog?(LogEntry(message: "Invalid port range.", type: .error))
            return
        }
        
        isScanning = true
        progress = 0.0
        onLog?(LogEntry(message: "Starting \(`protocol` == .tcp ? "TCP" : "UDP") port scan on \(targetIP) (\(startPort)-\(endPort))", type: .info))
        
        let semaphore = DispatchSemaphore(value: 100)
        let group = DispatchGroup()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let totalPorts = Double(endPort - startPort + 1)
            var scannedCount = 0.0
            
            for port in startPort...endPort {
                if !self.isScanning { break }
                
                group.enter()
                semaphore.wait()
                
                Thread.sleep(forTimeInterval: 0.005)
                
                self.scanQueue.async {
                    self.checkPort(host: targetIP, port: port, protocol: `protocol`) { isOpen in
                        if isOpen {
                            let desc = self.commonPorts[port] ?? ""
                            let portMsg = desc.isEmpty ? "Port \(port) is Open" : "Port \(port) (\(desc)) is Open"
                            let msg = "\(portMsg) (\(`protocol` == .tcp ? "TCP" : "UDP"))"
                            
                            DispatchQueue.main.async {
                                self.onLog?(LogEntry(message: msg, type: .success))
                            }
                        }
                        semaphore.signal()
                        group.leave()
                        
                        DispatchQueue.main.async {
                            scannedCount += 1
                            self.progress = scannedCount / totalPorts
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.isScanning = false
                self.progress = 1.0
                self.onLog?(LogEntry(message: "Port scan completed.", type: .info))
            }
        }
    }
    
    private func checkPort(host: String, port: Int, `protocol`: ScanProtocol, completion: @escaping (Bool) -> Void) {
        let hostEndpoint = NWEndpoint.Host(host)
        let portEndpoint = NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port))
        
        let params: NWParameters = `protocol` == .tcp ? .tcp : .udp
        let connection = NWConnection(host: hostEndpoint, port: portEndpoint, using: params)
        
        var hasCompleted = false
        let completionLock = NSLock()
        
        func safeCompletion(_ result: Bool) {
            completionLock.lock()
            defer { completionLock.unlock() }
            if !hasCompleted {
                hasCompleted = true
                completion(result)
            }
        }
        
        let timeoutWork = DispatchWorkItem {
            connection.cancel()
            safeCompletion(false)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0, execute: timeoutWork)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                timeoutWork.cancel()
                connection.cancel()
                safeCompletion(true)
            case .failed(_), .cancelled:
                timeoutWork.cancel()
                safeCompletion(false)
            default:
                break
            }
        }
        
        connection.start(queue: DispatchQueue.global())
    }
}
