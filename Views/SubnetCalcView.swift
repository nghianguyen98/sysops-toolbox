import SwiftUI

struct SubnetCalcView: View {
    @State private var ipAddress: String = "192.168.1.1"
    @State private var subnetMask: String = "255.255.255.0"
    @State private var cidr: Double = 24
    
    var info: SubnetInfo? {
        IPCalculator.calculate(ip: ipAddress, cidr: Int(cidr))
    }
    
    var body: some View {
        ToolCard(title: "Subnet Calculator", icon: "function") {
            VStack(spacing: 24) {
                // Inputs
                VStack(alignment: .leading, spacing: 16) {
                    // IP Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("IP Address")
                            .font(.callout)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        TextField("e.g. 10.0.0.1", text: $ipAddress)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    // Mask Input (New)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subnet Mask")
                            .font(.callout)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        TextField("e.g. 255.255.255.0", text: $subnetMask)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: subnetMask) {
                                if let newCIDR = IPCalculator.maskToCIDR(subnetMask) {
                                    cidr = Double(newCIDR)
                                }
                            }
                    }

                    // CIDR Slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("CIDR Prefix")
                                .font(.callout)
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text("/\(Int(cidr))")
                                .font(.headline)
                                .foregroundStyle(AppTheme.neonBlue)
                        }
                        
                        HStack(spacing: 12) {
                            Slider(value: $cidr, in: 0...32, step: 1)
                                .tint(AppTheme.neonBlue)
                                .onChange(of: cidr) {
                                    subnetMask = IPCalculator.cidrToMask(Int(cidr))
                                }
                            
                            Stepper("", value: $cidr, in: 0...32, step: 1)
                                .labelsHidden()
                                .onChange(of: cidr) {
                                    subnetMask = IPCalculator.cidrToMask(Int(cidr))
                                }
                        }
                    }
                }
                
                Divider()
                    .background(AppTheme.border)
                
                // Results Grid
                if let data = info {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ResultCard(title: "Network Address", value: data.networkAddress, icon: "network")
                        ResultCard(title: "Broadcast", value: data.broadcastAddress, icon: "antenna.radiowaves.left.and.right")
                        ResultCard(title: "Subnet Mask", value: data.subnetMask, icon: "checkerboard.shield")
                        ResultCard(title: "Usable Hosts", value: "\(data.totalUsable)", icon: "person.2.fill", highlight: true)
                        ResultCard(title: "First IP", value: data.firstUsable, icon: "arrow.right.to.line")
                        ResultCard(title: "Last IP", value: data.lastUsable, icon: "arrow.left.to.line")
                    }
                } else {
                    ContentUnavailableView {
                        Label("Invalid IP Address", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("Please enter a valid IPv4 address.")
                    }
                }
            }
        }
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let icon: String
    var highlight: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(highlight ? AppTheme.neonGreen : AppTheme.textSecondary)
                Spacer()
            }
            .font(.callout)
            
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(highlight ? AppTheme.neonGreen : AppTheme.textPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(title)
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.bgInput)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(highlight ? AppTheme.neonGreen.opacity(0.5) : AppTheme.border.opacity(0.5), lineWidth: 1)
        )
    }
}
