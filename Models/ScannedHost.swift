import Foundation

struct ScannedHost: Identifiable, Equatable {
    let id: UUID = UUID()
    let ipAddress: String
    var isOnline: Bool
    var openPorts: [Int] = []
    
    // New Fields
    var pingTime: Double? = nil // in ms
    var hostname: String? = nil
    var webBanner: String? = nil
    var vendor: String? // MAC Vendor (hard to get without root/ARP)
    
    static func == (lhs: ScannedHost, rhs: ScannedHost) -> Bool {
        return lhs.ipAddress == rhs.ipAddress && lhs.openPorts == rhs.openPorts && lhs.pingTime == rhs.pingTime && lhs.hostname == rhs.hostname
    }
}
