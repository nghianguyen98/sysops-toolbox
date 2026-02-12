import Foundation

struct NetworkInterfaceInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let ip: String
    let netmask: String
    
    var subnet: String {
        // Simple bitwise calculation for IPv4
        // Or string manipulation for 192.168.1.0 style
        
        guard let ipAddr = ipv4ToInt(ip), let mask = ipv4ToInt(netmask) else { return ip }
        let network = ipAddr & mask
        return intToIpv4(network)
    }
    
    // Helpers
    private func ipv4ToInt(_ ip: String) -> UInt32? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        var result: UInt32 = 0
        for part in parts {
            guard let intVal = UInt32(part) else { return nil }
            result = (result << 8) | intVal
        }
        return result
    }
    
    private func intToIpv4(_ int: UInt32) -> String {
        let p1 = (int >> 24) & 0xFF
        let p2 = (int >> 16) & 0xFF
        let p3 = (int >> 8) & 0xFF
        let p4 = int & 0xFF
        return "\(p1).\(p2).\(p3).\(p4)"
    }
}

class NetworkInterfaceUtils {
    static func getInterfaces() -> [NetworkInterfaceInfo] {
        var interfaces = [NetworkInterfaceInfo]()
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
            
            // Check for running IPv4 interfaces. Skip loopback.
            if (flags & (IFF_UP|IFF_RUNNING)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) {
                    if (flags & IFF_LOOPBACK) == 0 {
                        let name = String(cString: ptr.pointee.ifa_name)
                        
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        var netmask = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        
                        // Get IP
                        if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len),
                                       &hostname, socklen_t(hostname.count),
                                       nil, 0, NI_NUMERICHOST) == 0 {
                             
                             // Get Netmask (ifa_netmask)
                             if let maskPtr = ptr.pointee.ifa_netmask {
                                 getnameinfo(maskPtr, socklen_t(maskPtr.pointee.sa_len),
                                             &netmask, socklen_t(netmask.count),
                                             nil, 0, NI_NUMERICHOST)
                             }
                            
                            let ipString = String(cString: hostname)
                            let maskString = String(cString: netmask)
                            
                            if !ipString.isEmpty {
                                interfaces.append(NetworkInterfaceInfo(name: name, ip: ipString, netmask: maskString))
                            }
                        }
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return interfaces
    }
}
