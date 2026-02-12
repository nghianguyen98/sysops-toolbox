import Foundation
import Combine

class LANScannerViewModel: ObservableObject {
    @Published var subnet: String = "192.168.1.0"
    @Published var scannedHosts: [ScannedHost] = []
    @Published var isScanning: Bool = false
    @Published var progress: Double = 0.0
    @Published var availableInterfaces: [NetworkInterfaceInfo] = []
    
    private let service: LANScannerService
    private var cancellables = Set<AnyCancellable>()
    
    init(service: LANScannerService = LANScannerService()) {
        self.service = service
        self.loadInterfaces()
        
        // Bind Service -> ViewModel
        service.$scannedHosts
            .receive(on: DispatchQueue.main)
            .assign(to: \.scannedHosts, on: self)
            .store(in: &cancellables)
            
        service.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: \.isScanning, on: self)
            .store(in: &cancellables)
            
        service.$progress
            .receive(on: DispatchQueue.main)
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)
    }
    
    func loadInterfaces() {
        self.availableInterfaces = NetworkInterfaceUtils.getInterfaces()
        // Auto-select first interface subnet if not empty
        if let first = availableInterfaces.first, subnet == "192.168.1.0" {
            subnet = first.subnet
        }
    }
    
    func startScan() {
        service.scanSubnet(subnet: subnet)
    }
    
    func stopScan() {
        service.stopScan()
    }
    
    func getBadgeColor(port: Int) -> String? {
        // UI Helper for badges
        // This could return colors or just let View handle it.
        // Let's keep it simple here.
        return nil
    }
}
