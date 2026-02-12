import SwiftUI

struct ProcessListView: View {
    let processes: [NetworkTrafficMonitor.ProcessData]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("App")
                    .fontProDisplay(.caption, weight: .bold)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("Down")
                    .frame(width: 80, alignment: .trailing)
                    .fontProDisplay(.caption, weight: .bold)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("Up")
                    .frame(width: 80, alignment: .trailing)
                    .fontProDisplay(.caption, weight: .bold)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 4)
            
            // List
            ForEach(processes) { process in
                HStack {
                    Circle()
                        .fill(process.color)
                        .frame(width: 8, height: 8)
                    Text(process.name)
                        .fontProDisplay(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(process.downSpeed)
                        .fontProDisplay(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 80, alignment: .trailing)
                    Text(process.upSpeed)
                        .fontProDisplay(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                
                if process.id != processes.last?.id {
                    Divider().background(AppTheme.border.opacity(0.1))
                }
            }
        }
    }
}
