
import Foundation
import SwiftUI

enum LogType {
    case success
    case error
    case info
    case debug
}

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType
    let timestamp: Date = Date()
}
