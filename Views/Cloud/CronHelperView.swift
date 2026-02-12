import SwiftUI

struct CronHelperView: View {
    // State for Cron Parts
    @State private var minuteInput: String = "*"
    @State private var hourInput: String = "*"
    @State private var dayInput: String = "*"
    @State private var monthInput: String = "*"
    @State private var weekInput: String = "*"
    
    // Computed Expression
    private var expression: CronExpression {
        CronExpression(
            minute: minuteInput,
            hour: hourInput,
            dayOfMonth: dayInput,
            month: monthInput,
            dayOfWeek: weekInput
        )
    }
    
    // Presets
    private let presets = CronExpression.presets
    
    var body: some View {
        ToolCard(title: "Cron Expression Helper", icon: "clock") {
            VStack(spacing: 24) {
                
                // MARK: - Presets
                VStack(alignment: .leading, spacing: 10) {
                    Text("QUICK PRESETS")
                        .font(.callout.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(presets) { preset in
                                Button(action: { applyPreset(preset.expression) }) {
                                    Text(preset.name)
                                        .font(.body)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.bgDark.opacity(0.8))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(AppTheme.border, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Divider().background(AppTheme.border)
                
                // MARK: - Builder
                VStack(alignment: .leading, spacing: 16) {
                    Text("EXPRESSION BUILDER")
                        .font(.callout.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    HStack(spacing: 12) {
                        // Minute
                        cronPicker(title: "Minute", selection: $minuteInput, range: 0...59, addEvery: true)
                        
                        // Hour
                        cronPicker(title: "Hour", selection: $hourInput, range: 0...23, addEvery: true)
                        
                        // Day
                        cronPicker(title: "Day", selection: $dayInput, range: 1...31, addEvery: true)
                        
                        // Month
                        cronPicker(title: "Month", selection: $monthInput, range: 1...12, addEvery: true)
                        
                        // Week
                        cronPicker(title: "Weekday", selection: $weekInput, range: 0...6, addEvery: true)
                    }
                }
                
                Divider().background(AppTheme.border)
                
                // MARK: - Result
                VStack(spacing: 16) {
                    // Result Box
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.bgDark)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.neonCyan.opacity(0.3), lineWidth: 1))
                        
                        VStack(spacing: 12) {
                            // Cron String
                            HStack {
                                Text(expression.stringValue)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundStyle(AppTheme.neonCyan)
                                
                                Button(action: {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(expression.stringValue, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.title3)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 8)
                            }
                            
                            // Human Description
                            Text(expression.humanDescription)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                    }
                    .frame(height: 140)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // Helper for Picker
    @ViewBuilder
    private func cronPicker(title: String, selection: Binding<String>, range: ClosedRange<Int>, addEvery: Bool) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.callout)
                .foregroundStyle(AppTheme.textSecondary)
            
            Menu {
                if addEvery {
                    Button("Expression (*)") { selection.wrappedValue = "*" }
                    Button("Every 5 (*/5)") { selection.wrappedValue = "*/5" } // Common for minutes
                    Button("Every 10 (*/10)") { selection.wrappedValue = "*/10" }
                    Button("Every 15 (*/15)") { selection.wrappedValue = "*/15" }
                    Divider()
                }
                
                Picker("", selection: selection) {
                    if selection.wrappedValue == "*" {
                        Text("*").tag("*")
                    }
                    ForEach(range, id: \.self) { val in
                        Text("\(val)").tag("\(val)")
                    }
                }
                // If the current selection is a complex string (like */5), adding it to the picker is tricky with standard Picker
                // So we rely on the Button for complex checks, and Picker for simple ints.
                // However, standard Picker wants the selection to match a tag.
                // If selection is "*/5", the Picker won't show it selected.
                // A Custom approach is better:
            } label: {
                HStack {
                    Text(selection.wrappedValue)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(selection.wrappedValue == "*" ? AppTheme.textSecondary : AppTheme.neonGreen)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(AppTheme.bgDark.opacity(0.8))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func applyPreset(_ preset: CronExpression) {
        minuteInput = preset.minute
        hourInput = preset.hour
        dayInput = preset.dayOfMonth
        monthInput = preset.month
        weekInput = preset.dayOfWeek
    }
}
