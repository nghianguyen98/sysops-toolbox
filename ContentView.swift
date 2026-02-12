
import SwiftUI

enum ToolType: String, CaseIterable, Identifiable {
    case dash = "Latency Monitor"
    case ping = "Ping Utility"
    case portScan = "Port Scanner"
    case lanScan = "LAN Scanner"
    case subnetCalc = "Subnet Calculator"
    case chmod = "Chmod Calculator"
    case raid = "RAID Calculator"
    case trace = "Visual Trace"
    case password = "Password Generator"
    case systemd = "Systemd Gen"
    case docker = "Compose Builder"
    case qr = "QR Generator"
    case sshTunnel = "SSH Tunnel"

    case sslInspector = "SSL Inspector"
    case dnsLookup = "DNS Lookup"
    case ipGeo = "IP Geo Location"
    case whois = "Whois Lookup"
    case cron = "Cron Helper"
    case apiTester = "API Tester"
    case myIP = "My IP Info"
    
    // Info
    case about = "About"

    
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .dash: return "chart.bar.fill"
        case .ping: return "bolt.horizontal.circle.fill"
        case .portScan: return "waveform.path.ecg"
        case .lanScan: return "network"
        case .subnetCalc: return "function"
        case .trace: return "map"
        case .password: return "lock.shield"
        case .sslInspector: return "checkmark.shield.fill"
        case .dnsLookup: return "magnifyingglass.circle"
        case .ipGeo: return "mappin.and.ellipse"
        case .whois: return "person.text.rectangle"
        case .cron: return "clock"
        case .apiTester: return "antenna.radiowaves.left.and.right"
        case .myIP: return "laptopcomputer"
        case .chmod: return "lock.shield"
        case .raid: return "server.rack"
        case .systemd: return "gearshape.2"
        case .docker: return "shippingbox"


        case .qr: return "qrcode"
        case .sshTunnel: return "network.badge.shield.half.filled"
        
        case .about: return "info.circle"


        }
    }
    
    var usesStandardOutput: Bool {
        switch self {
        case .ping, .portScan, .lanScan, .trace:
            return true
        default:
            return false
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var searchText = ""
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isAutoScrollEnabled = true
    @State private var selectedTool: ToolType = .about
    @State private var selectedTab = "logs"
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var bindingIsDarkMode: Binding<Bool> {
        Binding(
            get: { isDarkMode },
            set: { isDarkMode = $0 }
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
        } detail: {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea()
                
                if selectedTool.usesStandardOutput {
                    VSplitView {
                        ScrollView {
                            VStack(spacing: 16) {
                                activeToolView
                            }
                            .padding()
                        }
                        .frame(minHeight: 300)
                        
                        outputView
                            .frame(minHeight: 200)
                    }
                    .navigationTitle(selectedTool.rawValue)
                } else {
                    if selectedTool == .dash {
                        activeToolView
                    } else {
                        ScrollView {
                            VStack(spacing: 24) { // Increased spacing for modern feel
                                activeToolView
                            }
                            .padding(24) // Larger padding
                        }
                        .navigationTitle(selectedTool.rawValue)
                    }
                }
            }
        }
    }
    
    private var sidebarView: some View {
        VStack {
            List(selection: $selectedTool) {
                Section("Monitor") {
                    NavigationLink(value: ToolType.dash) {
                        Label("Latency Monitor", systemImage: ToolType.dash.icon)
                    }
                    NavigationLink(value: ToolType.ping) {
                        Label("Ping Tool", systemImage: ToolType.ping.icon)
                    }
                }
                
                Section("Discovery & Network") {
                    NavigationLink(value: ToolType.portScan) {
                        Label("Port Scanner", systemImage: ToolType.portScan.icon)
                    }
                    NavigationLink(value: ToolType.lanScan) {
                        Label("LAN Scanner", systemImage: ToolType.lanScan.icon)
                    }
                    NavigationLink(value: ToolType.myIP) {
                        Label("My IP Info", systemImage: ToolType.myIP.icon)
                    }
                    NavigationLink(value: ToolType.trace) {
                        Label("Visual Trace", systemImage: ToolType.trace.icon)
                    }
                    NavigationLink(value: ToolType.dnsLookup) {
                        Label("DNS Lookup", systemImage: ToolType.dnsLookup.icon)
                    }
                    NavigationLink(value: ToolType.ipGeo) {
                        Label("IP Geo Location", systemImage: ToolType.ipGeo.icon)
                    }
                    NavigationLink(value: ToolType.whois) {
                        Label("Whois Lookup", systemImage: ToolType.whois.icon)
                    }
                }
                
                Section("Calculators") {
                    NavigationLink(value: ToolType.subnetCalc) {
                        Label("Subnet Calc", systemImage: ToolType.subnetCalc.icon)
                    }
                    NavigationLink(value: ToolType.raid) {
                        Label("RAID Calc", systemImage: ToolType.raid.icon)
                    }
                }
                
                Section("Cloud & DevOps") {
                    NavigationLink(value: ToolType.chmod) {
                        Label("Chmod Calc", systemImage: ToolType.chmod.icon)
                    }
                    NavigationLink(value: ToolType.systemd) {
                        Label("Systemd Gen", systemImage: ToolType.systemd.icon)
                    }
                    NavigationLink(value: ToolType.docker) {
                        Label("Docker Converter", systemImage: ToolType.docker.icon)
                    }
                    NavigationLink(value: ToolType.sshTunnel) {
                         Label("SSH Tunnel", systemImage: ToolType.sshTunnel.icon)
                    }

                    NavigationLink(value: ToolType.cron) {
                        Label("Cron Helper", systemImage: ToolType.cron.icon)
                    }
                }
                
                Section("Utilities") {
                    NavigationLink(value: ToolType.password) {
                        Label("Password Gen", systemImage: ToolType.password.icon)
                    }
                    NavigationLink(value: ToolType.sslInspector) {
                        Label("SSL Inspector", systemImage: ToolType.sslInspector.icon)
                    }
                    NavigationLink(value: ToolType.qr) {
                        Label("QR Generator", systemImage: ToolType.qr.icon)
                    }
                    NavigationLink(value: ToolType.apiTester) {
                        Label("API Tester", systemImage: ToolType.apiTester.icon)
                    }
                }
                
                Section("Info") {
                    NavigationLink(value: ToolType.about) {
                        Label("About", systemImage: ToolType.about.icon)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("NetOps")
            
            // Sidebar Footer
            VStack(spacing: 8) {
                Divider().background(AppTheme.border)
                Toggle("Dark Mode", isOn: bindingIsDarkMode)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                Text("by Nghia Nguyen").font(.caption).opacity(0.6)
            }
            .padding()
        }
        .navigationSplitViewColumnWidth(min: 260, ideal: 260, max: 260)
    }
    
    private var outputView: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                // TAB 1: LOGS
                ScrollViewReader { proxy in
                    List {
                        ForEach(viewModel.logs) { log in
                            LogRow(log: log)
                                .id(log.id)
                        }
                    }
                    .listStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.bgSecondary.opacity(0.5))
                    .onChange(of: viewModel.logs.count) {
                        if isAutoScrollEnabled, let lastLog = viewModel.logs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .tabItem { Label("Console", systemImage: "terminal") }
                .tag("logs")
                
                // TAB 2: RESULTS TABLE
                ScannerResultsTable(hosts: viewModel.lanScannerViewModel.scannedHosts)
                    .tabItem { Label("Results", systemImage: "tablecells") }
                    .tag("table")
            }
        }
        .navigationTitle("Output")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    if selectedTab == "logs" {
                        Button(action: { isAutoScrollEnabled.toggle() }) {
                            Label("Auto-Scroll", systemImage: isAutoScrollEnabled ? "arrow.up.left.and.arrow.down.right" : "arrow.down.doc")
                                .foregroundStyle(isAutoScrollEnabled ? AppTheme.neonGreen : AppTheme.textSecondary)
                        }
                    }
                    Button(action: { viewModel.clearLogs() }) {
                        Label("Clear Logs", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var activeToolView: some View {
        switch selectedTool {
        case .dash:
            PingDashboardView(viewModel: viewModel.dashboardViewModel)
        case .ping:
            PingView(pingService: viewModel.pingService)
        case .portScan:
            PortScanView(portScanService: viewModel.portScanService)
        case .lanScan:
            LANScannerView(viewModel: viewModel.lanScannerViewModel)
        case .subnetCalc:
            SubnetCalcView()
        case .chmod:
            ChmodCalcView()
        case .raid:
            RAIDCalcView()
        case .trace:
            TracerouteView(service: viewModel.tracerouteService)
        case .password:
            PasswordGenView()
        case .systemd:
            SystemdGenView()
        case .docker:
            DockerConverterView()
        case .qr:
            QRGeneratorView()
        case .sshTunnel:
            SSHTunnelView()

        case .sslInspector:
            SSLInspectorView()
        case .dnsLookup:
            DNSLookupView()
        case .ipGeo:
            IPGeoView()
        case .whois:
            WhoisLookupView()
        case .cron:
            CronHelperView()
        case .apiTester:
            APITesterView()
        case .myIP:
            MyIPView()
        case .about:
            AboutView()
        }
    }
}
