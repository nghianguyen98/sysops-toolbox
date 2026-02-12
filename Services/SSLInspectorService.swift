import Foundation
import Security
import Combine

struct SSLCertificateInfo: Identifiable {
    let id = UUID()
    let commonName: String
    let issuer: String
    let validFrom: Date
    let validTo: Date
    let isSelfSigned: Bool
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: validTo).day ?? 0
    }
    
    var status: SSLStatus {
        let days = daysRemaining
        if days < 0 { return .expired }
        if days < 30 { return .warning }
        return .valid
    }
}

enum SSLStatus {
    case valid
    case warning
    case expired
}

class SSLInspectorService: NSObject, URLSessionDelegate, ObservableObject {
    @Published var result: SSLCertificateInfo?
    @Published var isChecking = false
    @Published var errorMessage: String?
    
    private var currentTask: URLSessionDataTask?
    
    func checkSSL(domain: String) {
        guard !domain.isEmpty else { return }
        
        var cleanDomain = domain.lowercased()
        if !cleanDomain.hasPrefix("http") {
            cleanDomain = "https://" + cleanDomain
        }
        
        guard let url = URL(string: cleanDomain), let host = url.host else {
            errorMessage = "Invalid Domain"
            return
        }
        
        isChecking = true
        errorMessage = nil
        result = nil
        
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        var request = URLRequest(url: URL(string: "https://\(host)")!)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        let task = session.dataTask(with: request)
        currentTask = task
        task.resume()
    }
    
    func stopCheck() {
        currentTask?.cancel()
        currentTask = nil
        isChecking = false
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            
            if let certs = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate], !certs.isEmpty {
                parseCertificate(certs[0])
            }
            
            completionHandler(.cancelAuthenticationChallenge, nil)
            DispatchQueue.main.async {
                self.isChecking = false
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private func parseCertificate(_ cert: SecCertificate) {
        let commonName = SecCertificateCopySubjectSummary(cert) as String? ?? "Unknown"
        var issuer: String = "Unknown"
        var validFrom = Date()
        var validTo = Date()
        
        if let values = SecCertificateCopyValues(cert, nil, nil) as? [CFString: [CFString: Any]] {
            for (_, dict) in values {
                let label = dict[kSecPropertyKeyLabel] as? String ?? ""
                let value = dict[kSecPropertyKeyValue]
                
                // Extract Dates
                if label == "Not Valid Before" || label == "Validity Period Start" {
                    if let time = value as? Double {
                        validFrom = Date(timeIntervalSinceReferenceDate: time)
                    }
                } else if label == "Not Valid After" || label == "Validity Period End" {
                    if let time = value as? Double {
                        validTo = Date(timeIntervalSinceReferenceDate: time)
                    }
                } else if label == "Issuer" {
                    if let issuerArray = value as? [[CFString: Any]] {
                        for item in issuerArray {
                            let itemLabel = item[kSecPropertyKeyLabel] as? String ?? ""
                            if itemLabel == "Common Name" {
                                issuer = item[kSecPropertyKeyValue] as? String ?? "Unknown"
                            }
                        }
                    }
                }
            }
        }
        
        let isSelfSigned = (commonName == issuer && issuer != "Unknown") || commonName.contains("Self-Signed")
        
        DispatchQueue.main.async {
            self.result = SSLCertificateInfo(
                commonName: commonName,
                issuer: issuer,
                validFrom: validFrom,
                validTo: validTo,
                isSelfSigned: isSelfSigned
            )
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.isChecking = false
            if let error = error as NSError?, error.code != NSURLErrorCancelled {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
