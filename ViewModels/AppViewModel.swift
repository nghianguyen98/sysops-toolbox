
import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    
    let pingService = PingService()
    let portScanService = PortScanService()
    let lanScannerService = LANScannerService()
    
    @Published var lanScannerViewModel: LANScannerViewModel
    @Published var dashboardViewModel = DashboardViewModel()
    let tracerouteService = TracerouteService()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Init must wait for services
    init() {
        self.lanScannerViewModel = LANScannerViewModel(service: lanScannerService)
        
        // ... subscriptions ...
        
        // Forward objectWillChange from child VM to this VM
        lanScannerViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        dashboardViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        // Subscribe to Ping Service Logs
        pingService.onLog = { [weak self] log in
            DispatchQueue.main.async {
                self?.logs.append(log)
            }
        }
        
        // Subscribe to Port Scan Service Logs
        portScanService.onLog = { [weak self] log in
            DispatchQueue.main.async {
                self?.logs.append(log)
            }
        }
        
        // Subscribe to LAN Scanner Logs
        lanScannerService.onLog = { [weak self] log in
            DispatchQueue.main.async {
                self?.logs.append(log)
            }
        }
        
        // Subscribe to Traceroute Logs
        tracerouteService.onLog = { [weak self] log in
            DispatchQueue.main.async {
                self?.logs.append(log)
            }
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}
