
import SwiftUI
import Charts

enum RAIDLevel: String, CaseIterable, Identifiable {
    // Classic
    case raid0 = "RAID 0 (Stripe)"
    case raid1 = "RAID 1 (Mirror)"
    case raid5 = "RAID 5 (Parity)"
    case raid6 = "RAID 6 (Double Parity)"
    case raid10 = "RAID 10 (1+0)"
    case raid50 = "RAID 50 (5+0)"
    case raid60 = "RAID 60 (6+0)"
    
    // ZFS
    case raidz1 = "RAID-Z1 (ZFS)"
    case raidz2 = "RAID-Z2 (ZFS)"
    case raidz3 = "RAID-Z3 (ZFS)"
    
    var id: String { self.rawValue }
    
    var category: String {
        switch self {
        case .raidz1, .raidz2, .raidz3: return "ZFS / Proxmox"
        default: return "Standard RAID"
        }
    }
    
    var minDisks: Int {
        switch self {
        case .raid0, .raid1: return 2
        case .raid5, .raidz1: return 3
        case .raid6, .raid10, .raidz2: return 4
        case .raidz3: return 5
        case .raid50: return 6 // Min 3 per group * 2 groups
        case .raid60: return 8 // Min 4 per group * 2 groups
        }
    }
    
    func calculate(disks: Int, size: Double) -> (usable: Double, overhead: Double, parity: Double, unused: Double) {
        let n = Double(disks)
        var usable: Double = 0
        var parity: Double = 0
        var unused: Double = 0 // Space lost due to structure (like mirrors)
        
        switch self {
        case .raid0:
            usable = n * size
            
        case .raid1:
            usable = size
            unused = (n - 1) * size
            
        case .raid5, .raidz1:
            usable = (n - 1) * size
            parity = size
            
        case .raid6, .raidz2:
            usable = (n - 2) * size
            parity = 2 * size
            
        case .raid10:
            usable = (n / 2) * size
            unused = (n / 2) * size // Mirror copy
            
        case .raid50:
            // Assuming minimum 2 groups, logic: (n - 2) * size for parity across groups
            // Simplified: RAID 50 combines striping (RAID 0) with distributed parity (RAID 5)
            // Capacity = (N - NumberOfGroups) * Size
            // We assume optimal groups of 3-disk min (e.g. 6 disks = 2 groups of 3)
            let groups = 2.0 // Simplified for calculator
            parity = groups * size
            usable = (n - groups) * size
            
        case .raid60:
            let groups = 2.0
            parity = groups * 2 * size
            usable = (n - (groups * 2)) * size
            
        case .raidz3:
            usable = (n - 3) * size
            parity = 3 * size
        }
        
        // Safety check for calc
        if usable < 0 { usable = 0 }
        
        let total = n * size
        let overhead = total - usable
        return (usable, overhead, parity, unused)
    }
    
    var faultTolerance: String {
        switch self {
        case .raid0: return "0 drives (Risk High)"
        case .raid1: return "1 drive (per pair)"
        case .raid5, .raidz1: return "1 drive"
        case .raid6, .raidz2: return "2 drives"
        case .raidz3: return "3 drives"
        case .raid10: return "Up to half"
        case .raid50: return "1 drive per group"
        case .raid60: return "2 drives per group"
        }
    }
}

enum DiskUnit: String, CaseIterable, Identifiable {
    case TB, GB, MB
    var id: String { self.rawValue }
    
    var multiplier: Double {
        switch self {
        case .TB: return 1.0
        case .GB: return 1.0/1000.0
        case .MB: return 1.0/1000000.0
        }
    }
}

struct RAIDCalcView: View {
    @State private var selectedRAID: RAIDLevel = .raid5
    @State private var diskCount: Int = 4
    @State private var diskSize: Double = 4
    @State private var diskUnit: DiskUnit = .TB
    
    var body: some View {
        ToolCard(title: "Advanced RAID Calculator", icon: "server.rack") {
            HStack(alignment: .top, spacing: 24) {
                // Left Column: Configuration
                VStack(spacing: 24) {
                    configSection
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("THEORY & NOTES", systemImage: "book.closed")
                            .font(.callout.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Text(theoryText)
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.bgSecondary.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .frame(width: 320)
                
                // Right Column: Visualization
                VStack(spacing: 24) {
                    // KPI Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        BentoStat(title: "USABLE CAPACITY",
                                  value: formatSize(calc.usable),
                                  icon: "internaldrive.fill",
                                  color: AppTheme.neonGreen)
                        
                        BentoStat(title: "PROTECTION / PARITY",
                                  value: formatSize(calc.parity),
                                  icon: "shield.check.fill",
                                  color: AppTheme.neonCyan)
                        
                        BentoStat(title: "UNUSED / MIRROR",
                                  value: formatSize(calc.unused),
                                  icon: "doc.on.doc.fill",
                                  color: AppTheme.neonOrange)
                        
                        BentoStat(title: "TOTAL RAW",
                                  value: formatSize(Double(diskCount) * diskSize),
                                  icon: "server.rack",
                                  color: AppTheme.border)
                    }
                    
                    // Main Chart Area
                    HStack(spacing: 24) {
                        // Donut Chart
                        ZStack {
                            Chart {
                                SectorMark(
                                    angle: .value("Usable", calc.usable),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 2
                                )
                                .foregroundStyle(AppTheme.neonGreen)
                                .cornerRadius(4)
                                
                                SectorMark(
                                    angle: .value("Parity", calc.parity),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 2
                                )
                                .foregroundStyle(AppTheme.neonCyan)
                                .cornerRadius(4)
                                
                                SectorMark(
                                    angle: .value("Unused", calc.unused),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 2
                                )
                                .foregroundStyle(AppTheme.neonOrange)
                                .cornerRadius(4)
                            }
                            .frame(height: 220)
                            
                            VStack {
                                Text("Efficiency")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(String(format: "%.0f%%", efficiency * 100))
                                    .font(.system(.title, design: .rounded).bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                        .padding(24)
                        .background(AppTheme.bgDark)
                        .cornerRadius(20)
                        
                        // Tolerance Info
                        VStack(alignment: .leading, spacing: 16) {
                            Label("FAULT TOLERANCE", systemImage: "cross.case.fill")
                                .font(.callout.bold())
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            Text(selectedRAID.faultTolerance)
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .foregroundStyle(selectedRAID.faultTolerance.contains("0") ? AppTheme.neonRed : AppTheme.neonGreen)
                                .multilineTextAlignment(.leading)
                            
                            Divider()
                            
                            HStack {
                                Text("Read Speed:")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text(readSpeedRating)
                                    .font(.footnote.bold())
                                    .foregroundStyle(AppTheme.neonGreen)
                            }
                            
                            HStack {
                                Text("Write Speed:")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text(writeSpeedRating)
                                    .font(.footnote.bold())
                                    .foregroundStyle(AppTheme.neonOrange)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.bgSecondary.opacity(0.3))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Logic Helpers
    private var calc: (usable: Double, overhead: Double, parity: Double, unused: Double) {
        selectedRAID.calculate(disks: diskCount, size: diskSize)
    }
    
    private var efficiency: Double {
        let total = Double(diskCount) * diskSize
        guard total > 0 else { return 0 }
        return calc.usable / total
    }
    
    private func formatSize(_ val: Double) -> String {
        return String(format: "%.1f %@", val, diskUnit.rawValue)
    }
    
    // MARK: - Ratings
    var readSpeedRating: String {
        // Simplified heuristics
        switch selectedRAID {
        case .raid0: return "Excellent (Nx)"
        case .raid1: return "Good (2x)"
        case .raid10: return "Excellent (Nx)"
        case .raid5, .raid6, .raid50, .raid60, .raidz1, .raidz2, .raidz3:
            return "Good (Striped)"
        }
    }
    
    var writeSpeedRating: String {
        switch selectedRAID {
        case .raid0: return "Excellent (Nx)"
        case .raid1: return "Fair (1x)"
        case .raid10: return "Good (Nx/2)"
        case .raid5, .raid6, .raidz1, .raidz2, .raidz3:
            return "Fair (Parity Calc)"
        case .raid50, .raid60: return "Good"
        }
    }
    
    var theoryText: String {
        switch selectedRAID {
        case .raid0: return "Striping across all drives. Fastest performance but ZERO data protection. One drive failure = Total data loss."
        case .raid1: return "Mirroring. Exact copy on optimal drives. High redundancy, higher cost per GB."
        case .raid5: return "Striping with single distributed parity. Good read speed, balance of space/safety. Rebuilds are intensive."
        case .raid6: return "Striping with double distributed parity. Can survive 2 concurrent failures. Slower writes due to dual parity calc."
        case .raid10: return "Stripe of Mirrors. Best performance/redundancy combo usually. Fast rebuilds but expensive (50% capacity lost)."
        case .raidz1, .raidz2, .raidz3: return "ZFS proprietary RAID. Solves 'write hole' issue. Z1=RAID5, Z2=RAID6 (double parity), Z3=Triple parity (extreme safety)."
        default: return "Combined standard RAID levels."
        }
    }
    
    // MARK: - Subviews
    private var configSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("CONFIGURATION")
                    .font(.callout.bold())
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            .padding(16)
            .background(AppTheme.bgSecondary.opacity(0.5))
            
            VStack(spacing: 20) {
                // RAID Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("RAID Level")
                        .font(.callout)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Picker("Select", selection: $selectedRAID) {
                        ForEach(RAIDLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.neonCyan)
                    .onChange(of: selectedRAID) {
                        if diskCount < selectedRAID.minDisks {
                            diskCount = selectedRAID.minDisks
                        }
                    }
                }
                
                Divider()
                
                // Disk Count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of Drives")
                        .font(.callout)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    HStack(spacing: 0) {
                        // Decrement
                        Button(action: {
                            if diskCount > selectedRAID.minDisks { diskCount -= 1 }
                        }) {
                            Image(systemName: "minus")
                                .frame(width: 32, height: 28) // Compact size
                                .background(AppTheme.bgSecondary.opacity(0.3))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .disabled(diskCount <= selectedRAID.minDisks)
                        
                        Divider().background(AppTheme.border.opacity(0.3))
                        
                        // Input Field
                        TextField("Count", value: $diskCount, format: .number)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .font(.system(.subheadline, design: .monospaced).bold()) // Slightly smaller font
                            .foregroundStyle(AppTheme.neonCyan)
                            .frame(height: 28) // Match button height
                            .background(AppTheme.bgDark.opacity(0.3))
                        
                        Divider().background(AppTheme.border.opacity(0.3))
                        
                        // Increment
                        Button(action: {
                            if diskCount < 128 { diskCount += 1 }
                        }) {
                            Image(systemName: "plus")
                                .frame(width: 32, height: 28) // Compact size
                                .background(AppTheme.bgSecondary.opacity(0.3))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .disabled(diskCount >= 128)
                    }
                    .frame(height: 28) // Force container height
                    .background(AppTheme.bgDark.opacity(0.3))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.border.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Divider()
                
                // Disk Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Drive Size")
                        .font(.callout)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    HStack {
                        TextField("Size", value: $diskSize, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.body.monospaced())
                        
                        Picker("Unit", selection: $diskUnit) {
                            ForEach(DiskUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.bgDark)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border.opacity(0.3), lineWidth: 1))
    }
}

// Modern Bento Stat Card
struct BentoStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.body.bold())
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.footnote.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Text(value)
                .font(.title2.monospaced())
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.0)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}
