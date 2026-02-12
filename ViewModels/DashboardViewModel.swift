import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var monitors: [PingMonitor] = []
    
    func addMonitor(hostname: String) {
        let monitor = PingMonitor(hostname: hostname)
        monitors.append(monitor)
        monitor.start()
    }
    
    func removeMonitor(_ monitor: PingMonitor) {
        monitor.stop()
        monitors.removeAll(where: { $0.id == monitor.id })
    }
}
