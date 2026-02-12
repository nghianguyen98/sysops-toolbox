import Foundation

struct CurlRequest {
    var url: String
    var method: HTTPMethod
    var headers: [String: String]
    var body: String?
}

enum CurlError: LocalizedError {
    case invalidFormat
    case noURLFound
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat: return "Invalid cURL command format."
        case .noURLFound: return "No URL found in the cURL command."
        }
    }
}

class CurlParser {
    static func parse(_ command: String) throws -> CurlRequest {
        let cleanCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanCommand.lowercased().hasPrefix("curl") else {
            throw CurlError.invalidFormat
        }
        
        // Basic argument splitting (handling quotes roughly)
        // This is a simplified parser. For production-grade, a full tokenizer is needed.
        // We will use regex to find specific flags.
        
        var url: String?
        var method: HTTPMethod = .get
        var headers: [String: String] = [:]
        var body: String?
        
        // 1. Extract URL (Assuming it starts with http/https and is not a header value)
        // Regex for URL: https?://[^\s"']+
        let urlPattern = #"https?://[^\s"']+"#
        if let range = cleanCommand.range(of: urlPattern, options: .regularExpression) {
            url = String(cleanCommand[range])
        }
        
        // 2. method (-X POST, --request GET)
        let methodPattern = #"(?:-X|--request)\s+([A-Z]+)"#
        if let regex = try? NSRegularExpression(pattern: methodPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: cleanCommand, range: NSRange(cleanCommand.startIndex..., in: cleanCommand)),
           let range = Range(match.range(at: 1), in: cleanCommand) {
            let methodString = String(cleanCommand[range]).uppercased()
            if let m = HTTPMethod(rawValue: methodString) {
                method = m
            }
        }
        
        // 3. Headers (-H "Key: Value")
        // Regex: -H\s+['"]([^'"]+)['"]
        let headerPattern = #"(?:-H|--header)\s+['"]([^'"]+)['"]"#
        if let regex = try? NSRegularExpression(pattern: headerPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: cleanCommand, range: NSRange(cleanCommand.startIndex..., in: cleanCommand))
            for match in matches {
                if let range = Range(match.range(at: 1), in: cleanCommand) {
                    let headerString = String(cleanCommand[range])
                    let parts = headerString.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        headers[parts[0]] = parts[1]
                    }
                }
            }
        }
        
        // 4. Body (-d "data", --data-raw "data")
        // Regex: (?:-d|--data|--data-raw)\s+['"]([^'"]+)['"]
        // Note: supporting single and double quotes for the data content is tricky with regex if nested.
        // Simplified: capture content inside outermost quotes if possible.
        // Let's look for -d '...' or -d "..."
        let bodyPatterns = [
            #"(?:-d|--data|--data-raw)\s+'([^']+)'"#, // Single quoted
            #"(?:-d|--data|--data-raw)\s+"([^"]+)""#  // Double quoted
        ]
        
        for pattern in bodyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: cleanCommand, range: NSRange(cleanCommand.startIndex..., in: cleanCommand)),
               let range = Range(match.range(at: 1), in: cleanCommand) {
                body = String(cleanCommand[range])
                // Implicit POST if data is present and method is GET
                if method == .get {
                    method = .post
                }
                break 
            }
        }
        
        guard let finalURL = url else {
            throw CurlError.noURLFound
        }
        
        return CurlRequest(url: finalURL, method: method, headers: headers, body: body)
    }
}
