import Foundation

struct CronExpression {
    var minute: String = "*"
    var hour: String = "*"
    var dayOfMonth: String = "*"
    var month: String = "*"
    var dayOfWeek: String = "*"
    
    var stringValue: String {
        "\(minute) \(hour) \(dayOfMonth) \(month) \(dayOfWeek)"
    }
    
    var humanDescription: String {
        var parts: [String] = []
        
        // Time
        if minute == "*" && hour == "*" {
            parts.append("Every minute")
        } else if minute.starts(with: "*/") {
            let interval = minute.dropFirst(2)
            if hour == "*" {
                 parts.append("Every \(interval) minutes")
            } else {
                 parts.append("Every \(interval) minutes past hour \(hour)")
            }
        } else if minute != "*" && hour == "*" {
             parts.append("At minute \(minute) of every hour")
        } else if minute != "*" && hour != "*" {
             parts.append("At \(String(format: "%02d:%02d", Int(hour) ?? 0, Int(minute) ?? 0))")
        } else if minute == "0" && hour != "*" { // verification catch: usually covered above but if minute is specifically 0
             parts.append("At \(hour):00")
        } else {
             parts.append("At \(hour):\(minute)")
        }
        
        // Date
        if dayOfMonth != "*" {
            parts.append("on day \(dayOfMonth) of the month")
        }
        
        if month != "*" {
            // Check if month is a name or number
            if let monthInt = Int(month), monthInt >= 1 && monthInt <= 12 {
                 let formatter = DateFormatter()
                 let monthName = formatter.monthSymbols[monthInt - 1]
                 parts.append("in \(monthName)")
            } else {
                 parts.append("in \(month)")
            }
        }
        
        if dayOfWeek != "*" {
             if let dayInt = Int(dayOfWeek), dayInt >= 0 && dayInt <= 6 {
                 let formatter = DateFormatter()
                 // 0 is usually Sunday in cron, verify platform specific but standard is 0-6 (Sun-Sat) or 1-7. 
                 // Let's assume 0 = Sunday for standard cron, 1 = Mon...
                 // Swift's weekdaySymbols starts at Sunday (index 0)
                 let dayName = formatter.weekdaySymbols[dayInt]
                 parts.append("on \(dayName)")
             } else {
                  parts.append("on day-of-week \(dayOfWeek)")
             }
        }
        
        if parts.isEmpty {
            return "Every minute"
        }
        
        return parts.joined(separator: ", ")
    }
    
    struct Preset: Identifiable {
        let id = UUID()
        let name: String
        let expression: CronExpression
    }

    static let presets: [Preset] = [
        Preset(name: "Every Minute", expression: CronExpression(minute: "*", hour: "*", dayOfMonth: "*", month: "*", dayOfWeek: "*")),
        Preset(name: "Every 5 Minutes", expression: CronExpression(minute: "*/5", hour: "*", dayOfMonth: "*", month: "*", dayOfWeek: "*")),
        Preset(name: "Every Hour", expression: CronExpression(minute: "0", hour: "*", dayOfMonth: "*", month: "*", dayOfWeek: "*")),
        Preset(name: "Daily at Midnight", expression: CronExpression(minute: "0", hour: "0", dayOfMonth: "*", month: "*", dayOfWeek: "*")),
        Preset(name: "Every Sunday", expression: CronExpression(minute: "0", hour: "0", dayOfMonth: "*", month: "*", dayOfWeek: "0")),
        Preset(name: "Monthly (1st)", expression: CronExpression(minute: "0", hour: "0", dayOfMonth: "1", month: "*", dayOfWeek: "*"))
    ]
}
