import Foundation

struct SubnetInfo {
    let networkAddress: String
    let broadcastAddress: String
    let subnetMask: String
    let firstUsable: String
    let lastUsable: String
    let totalUsable: Int
    let cidr: String
}

class IPCalculator {
    
    static func calculate(ip: String, cidr: Int) -> SubnetInfo? {
        guard let ipInt = ipToInt(ip) else { return nil }
        
        let shiftCount = 32 - cidr
        let mask: UInt32 = (shiftCount >= 32) ? 0 : (0xFFFFFFFF << UInt32(shiftCount))
        let network: UInt32 = ipInt & mask
        let broadcast: UInt32 = network | (~mask)
        
        // Ensure accurate comparison
        let firstUsable: UInt32 = network + 1
        let lastUsable: UInt32 = broadcast > 0 ? broadcast - 1 : 0
        
        // Handle special cases /31 and /32
        var usableCount = 0
        if cidr == 32 {
            usableCount = 1
        } else if cidr == 31 {
            usableCount = 2
        } else {
             usableCount = Int(broadcast) - Int(network) - 1
             if usableCount < 0 { usableCount = 0 }
        }
        
        // For /31 and /32 ranges usually differ, but keeping simple specific logic often omitted in basic calcs.
        // Standard logic:
        // /32: Network = Host, Broadcast = Host. Usable 1?
        // Let's stick to standard practice: 2^(32-CIDR) - 2 for normal subnets.
        // If CIDR=32 -> 1 host (usable 1).
        // If CIDR=31 -> 2 hosts (usable 0 effectively in standard networking, or 2 in point-to-point).
        // Let's implement standard "usable hosts = 2^(n) - 2" except for 31/32 specialized handling.
        
        let totalHosts = pow(2.0, Double(32 - cidr))
        var realUsable = Int(totalHosts) - 2
        if cidr == 32 { realUsable = 1 }
        else if cidr == 31 { realUsable = 2 } // Point-to-point links usually treat net/broadcast as usable IPs.
        
        return SubnetInfo(
            networkAddress: intToIP(network),
            broadcastAddress: intToIP(broadcast),
            subnetMask: intToIP(mask),
            firstUsable: intToIP(firstUsable),
            lastUsable: intToIP(lastUsable),
            totalUsable: max(0, realUsable),
            cidr: "/\(cidr)"
        )
    }
    
    // MARK: - Helpers
    
    static func ipToInt(_ ip: String) -> UInt32? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        
        var result: UInt32 = 0
        for part in parts {
            guard let val = UInt32(part), val <= 255 else { return nil }
            result = (result << 8) | val
        }
        return result
    }
    
    static func intToIP(_ val: UInt32) -> String {
        let p1 = (val >> 24) & 0xFF
        let p2 = (val >> 16) & 0xFF
        let p3 = (val >> 8) & 0xFF
        let p4 = val & 0xFF
        return "\(p1).\(p2).\(p3).\(p4)"
    }
    
    static func maskToCIDR(_ mask: String) -> Int? {
        guard let maskInt = ipToInt(mask) else { return nil }
        
        // Count consecutive leading 1s
        var count = 0
        var test: UInt32 = 0x80000000
        while test > 0 && (maskInt & test) != 0 {
            count += 1
            test >>= 1
        }
        
        // Basic check: is the rest 0?
        let shiftCount = 32 - count
        let checkMask: UInt32 = (shiftCount >= 32) ? 0 : (0xFFFFFFFF << UInt32(shiftCount))
        return (maskInt == checkMask) ? count : nil
    }
    
    static func cidrToMask(_ cidr: Int) -> String {
        let shiftCount = 32 - cidr
        let mask: UInt32 = (shiftCount >= 32) ? 0 : (0xFFFFFFFF << UInt32(shiftCount))
        return intToIP(mask)
    }
}
