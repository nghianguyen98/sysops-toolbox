import Foundation
import Network
import Combine

class LANScannerService: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0.0
    @Published var scannedHosts: [ScannedHost] = []
    
    var onLog: ((LogEntry) -> Void)?
    
    // Config
    private let commonPorts = [21, 22, 23, 80, 443, 3389, 5900, 8080, 8291]
    
    // Concurrency Control
    // We strictly limit the number of active checking threads/connections to avoid exhausting file descriptors or ports.
    // 'hostSemaphore' controls how many IPs we scan in parallel (Stage 1).
    // 'scanQueue' is a serial queue for results processing to avoid array race conditions.
    private let hostSemaphore = DispatchSemaphore(value: 8) 
    private let serviceScanQueue = OperationQueue() 
    
    init() {
        serviceScanQueue.maxConcurrentOperationCount = 4 // Only scan services for 4 hosts at a time
    }
    
    func scanSubnet(subnet: String) {
        guard !isScanning else { return }
        isScanning = true
        progress = 0.0
        scannedHosts.removeAll()
        
        // Basic subnet parsing
        var baseIP = subnet.trimmingCharacters(in: .whitespacesAndNewlines)
        if let lastDot = baseIP.lastIndex(of: "."), baseIP.components(separatedBy: ".").count == 4 {
             if baseIP.hasSuffix(".0") {
                 baseIP = String(baseIP.prefix(upTo: lastDot))
             }
        }
        // Ensure we have 3 parts "192.168.1"
        let components = baseIP.split(separator: ".")
        if components.count != 3 {
             onLog?(LogEntry(message: "Invalid Subnet. Use '192.168.1.0'", type: .error))
             isScanning = false
             return
        }
        let prefix = baseIP
        
        onLog?(LogEntry(message: "Scanning \(prefix).1-254", type: .info))
        
        // Run in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let totalHosts = 254
            let group = DispatchGroup()
            
            for i in 1...totalHosts {
                if !self.isScanning { break }
                let hostIP = "\(prefix).\(i)"
                
                group.enter()
                self.hostSemaphore.wait()
                
                self.checkHostOnline(ip: hostIP) { isOnline, pingTime in
                    // Update Progress (approx)
                    DispatchQueue.main.async {
                         // Careful with 254 updates triggering 254 redraws. 
                         // Ideally we'd batch, but for now simple math:
                         if self.isScanning {
                             self.progress = Double(i) / Double(totalHosts)
                         }
                    }

                    if isOnline {
                        // Found Host
                        let host = ScannedHost(ipAddress: hostIP, isOnline: true, pingTime: pingTime)
                        self.addOrUpdateHost(host)
                        
                        // Queue Service Scan (Stage 2)
                        // We use an OperationQueue to control concurrency separate from the discovery loop
                        self.serviceScanQueue.addOperation {
                            self.scanServices(for: host.id, ip: hostIP)
                        }
                    } else {
                        // Offline
                        let host = ScannedHost(ipAddress: hostIP, isOnline: false)
                        self.addOrUpdateHost(host)
                    }
                    
                    self.hostSemaphore.signal()
                    group.leave()
                }
            }
            
            group.wait()
            
            // Wait for service scans to clear too? 
            // The service scans might still be running. We'll let them finish.
            self.serviceScanQueue.waitUntilAllOperationsAreFinished()
            
            DispatchQueue.main.async {
                self.isScanning = false
                self.progress = 1.0
                self.onLog?(LogEntry(message: "Scan Complete.", type: .success))
            }
        }
    }
    
    // Safe Array Update
    private func addOrUpdateHost(_ host: ScannedHost) {
        DispatchQueue.main.async {
            // Check if exists
            if let index = self.scannedHosts.firstIndex(where: { $0.ipAddress == host.ipAddress }) {
                self.scannedHosts[index] = host
            } else {
                self.scannedHosts.append(host)
            }
            // Keep sorted
            self.scannedHosts.sort { $0.ipAddress.localizedStandardCompare($1.ipAddress) == .orderedAscending }
        }
    }
    
    func stopScan() {
        isScanning = false
        serviceScanQueue.cancelAllOperations()
    }
    
    // MARK: - Stage 1: Check Online (Ping Sweep equivalent)
    private func checkHostOnline(ip: String, completion: @escaping (Bool, Double?) -> Void) {
        let start = Date()
        
        // List of ports to try for "Online" check. 
        // If ANY of these respond, we consider the host online.
        let discoveryPorts = [80, 443, 22, 53, 445, 139] 
        // 445/139 are good for Windows/SMB, 53 for DNS/Routers, 22/80/443 for Linux/Web
        
        let discoveryGroup = DispatchGroup()
        let resultQueue = DispatchQueue(label: "com.nettool.discovery.\(ip)")
        var isOnline = false
        var firstPingTime: Double? = nil
        
        for port in discoveryPorts {
            discoveryGroup.enter()
            
            // Short timeout (0.5s) to scan fast
            checkPort(host: ip, port: port, timeout: 0.5) { isOpen in
                if isOpen {
                    resultQueue.async {
                         if !isOnline {
                             isOnline = true
                             let duration = Date().timeIntervalSince(start) * 1000
                             firstPingTime = duration
                         }
                    }
                }
                discoveryGroup.leave()
            }
        }
        
        discoveryGroup.notify(queue: .global()) {
            completion(isOnline, firstPingTime)
        }
    }
    
    // MARK: - Stage 2: Service Scan
    private func scanServices(for hostID: UUID, ip: String) {
        // 1. Resolve Hostname
        let hostname = resolveHostname(ip: ip)
        DispatchQueue.main.async {
            if let index = self.scannedHosts.firstIndex(where: { $0.id == hostID }) {
                self.scannedHosts[index].hostname = hostname
            }
        }
        
        // 2. Scan Ports
        for port in self.commonPorts {
            if !self.isScanning { break }
            // Sync check inside this async operation
            let sema = DispatchSemaphore(value: 0)
            
            self.checkPort(host: ip, port: port, timeout: 0.5) { isOpen in
                if isOpen {
                    DispatchQueue.main.async {
                         if let index = self.scannedHosts.firstIndex(where: { $0.id == hostID }) {
                             var h = self.scannedHosts[index]
                             if !h.openPorts.contains(port) {
                                 h.openPorts.append(port)
                                 h.openPorts.sort()
                                 self.scannedHosts[index] = h
                             }
                         }
                    }
                    
                    // Web Banner?
                     if [80, 443, 8080].contains(port) {
                         self.grabWebBanner(ip: ip, port: port) { banner in
                             if let b = banner {
                                 DispatchQueue.main.async {
                                     if let index = self.scannedHosts.firstIndex(where: { $0.id == hostID }) {
                                         if self.scannedHosts[index].webBanner == nil {
                                             self.scannedHosts[index].webBanner = b
                                         }
                                     }
                                 }
                             }
                         }
                     }
                }
                sema.signal()
            }
            sema.wait() // Wait for port check to finish before next port (throttling per host)
        }
    }
    
    private func resolveHostname(ip: String) -> String? {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        hints.ai_flags = AI_CANONNAME
        
        var res: UnsafeMutablePointer<addrinfo>?
        
        if getaddrinfo(ip, nil, &hints, &res) == 0 {
            defer { freeaddrinfo(res) }
            
            if let addr = res?.pointee.ai_addr {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                
                // Remove NI_NAMEREQD to allow returning something even if not FQDN
                if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, 0) == 0 {
                    let name = String(cString: host)
                    return name != ip ? name : nil // Only return if it's not just the IP itself
                }
            }
        }
        return nil
    }
    
    private func grabWebBanner(ip: String, port: Int, completion: @escaping (String?) -> Void) {
        let endpoint = NWEndpoint.Host(ip)
        let portEndpoint = NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port))
        let params: NWParameters = .tcp
        let connection = NWConnection(host: endpoint, port: portEndpoint, using: params)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let request = "HEAD / HTTP/1.0\r\n\r\n"
                connection.send(content: request.data(using: .utf8), completion: .contentProcessed({ _ in }))
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
                    if let data = data, let response = String(data: data, encoding: .utf8),
                       let range = response.range(of: "Server: ") {
                        let substring = response[range.upperBound...]
                        let line = substring.components(separatedBy: "\r\n").first
                        completion(line)
                    } else {
                        completion(nil)
                    }
                    connection.cancel()
                }
            case .failed(_), .cancelled:
                completion(nil)
            default: break
            }
        }
        connection.start(queue: DispatchQueue.global())
        // Banner grab is best-effort, no strict timeout needed here as it's async detached
    }
    
    private func checkPort(host: String, port: Int, timeout: TimeInterval, completion: @escaping (Bool) -> Void) {
        let endpoint = NWEndpoint.Host(host)
        let portEndpoint = NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port))
        let connection = NWConnection(host: endpoint, port: portEndpoint, using: .tcp)
        
        var hasCalledBack = false
        
        connection.stateUpdateHandler = { state in
            if hasCalledBack { return }
            switch state {
            case .ready:
                hasCalledBack = true
                connection.cancel()
                completion(true)
            case .failed(_), .cancelled:
                hasCalledBack = true
                connection.cancel() // Double cancel safe
                completion(false)
            default: break
            }
        }
        
        connection.start(queue: DispatchQueue.global())
        
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            if !hasCalledBack {
                hasCalledBack = true
                connection.cancel()
                completion(false)
            }
        }
    }
}
