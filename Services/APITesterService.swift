import Foundation
import Combine

enum HTTPMethod: String, CaseIterable, Identifiable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
    
    var id: String { rawValue }
}

struct APIResponse {
    let statusCode: Int
    let body: String
    let headers: [AnyHashable: Any]
    let latency: TimeInterval
    let error: Error?
}

@MainActor
class APITesterService: ObservableObject {
    @Published var isRequesting = false
    @Published var lastResponse: APIResponse?
    
    func sendRequest(url: String, method: HTTPMethod, headers: [String: String], body: String) async {
        guard let requestURL = URL(string: url) else {
            self.lastResponse = APIResponse(statusCode: 0, body: "Invalid URL", headers: [:], latency: 0, error: URLError(.badURL))
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        
        // Headers
        for (key, value) in headers {
            if !key.isEmpty {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Body
        if !body.isEmpty && (method != .get && method != .head) {
            request.httpBody = body.data(using: .utf8)
        }
        
        isRequesting = true
        let startTime = Date()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let latency = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.lastResponse = APIResponse(statusCode: 0, body: "Invalid Response Type", headers: [:], latency: latency, error: nil)
                isRequesting = false
                return
            }
            
            let bodyString = prettyJson(from: data) ?? String(data: data, encoding: .utf8) ?? "Unable to decode body"
            
            self.lastResponse = APIResponse(
                statusCode: httpResponse.statusCode,
                body: bodyString,
                headers: httpResponse.allHeaderFields,
                latency: latency,
                error: nil
            )
            
        } catch {
            let latency = Date().timeIntervalSince(startTime)
            self.lastResponse = APIResponse(
                statusCode: 0,
                body: error.localizedDescription,
                headers: [:],
                latency: latency,
                error: error
            )
        }
        
        isRequesting = false
    }
    
    private func prettyJson(from data: Data) -> String? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
