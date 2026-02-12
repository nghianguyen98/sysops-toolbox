import Foundation
import Combine
import MapKit

struct IPGeoInfo: Codable, Identifiable {
    var id = UUID()
    let success: Bool?
    let message: String?
    let ip: String?
    let city: String?
    let region: String?
    let country: String?
    let country_code: String?
    let latitude: Double?
    let longitude: Double?
    let timezone: IPWhoisTimezone?
    let connection: IPGeoConnection?
    
    struct IPWhoisTimezone: Codable {
        let id: String?
        let current_time: String?
    }
    
    struct IPGeoConnection: Codable {
        let asn: Int?
        let isp: String?
        let org: String?
    }
    
    private enum CodingKeys: String, CodingKey {
        case success, message, ip, city, region, country, country_code, latitude, longitude, timezone, connection
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

class IPGeoService: ObservableObject {
    @Published var result: IPGeoInfo?
    @Published var isFetching = false
    @Published var errorMessage: String?
    
    func fetchLocation(for query: String) {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return }
        
        isFetching = true
        errorMessage = nil
        
        // Switched to ipwho.is for superior reliability and HTTPS support
        let urlString = "https://ipwho.is/\(cleanQuery)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isFetching = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: IPGeoInfo.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = "Connection error: \(error.localizedDescription)"
                    self.isFetching = false
                }
            } receiveValue: { geo in
                if geo.success == false {
                    self.errorMessage = geo.message ?? "No location data found."
                } else if geo.latitude == nil {
                    self.errorMessage = "Incomplete location data."
                } else {
                    self.result = geo
                }
                self.isFetching = false
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
