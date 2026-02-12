import SwiftUI
import MapKit

struct IPGeoView: View {
    @StateObject private var service = IPGeoService()
    @State private var query = ""
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        ToolCard(title: "IP Geo Location", icon: "mappin.and.ellipse") {
            VStack(spacing: 20) {
                // Search Box
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundStyle(AppTheme.neonCyan)
                        TextField("Enter IP or Domain (e.g. 8.8.8.8)", text: $query)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(12)
                    .background(AppTheme.bgDark.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.neonCyan.opacity(0.3), lineWidth: 1))
                    
                    Button(action: {
                        service.fetchLocation(for: query)
                    }) {
                        if service.isFetching {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("LOCATE")
                                .font(.system(.subheadline, design: .monospaced).bold())
                        }
                    }
                    .frame(width: 100, height: 44)
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.neonCyan)
                    .disabled(service.isFetching || query.isEmpty)
                }
                
                if let error = service.errorMessage {
                    Text(error)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(AppTheme.neonRed)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.neonRed.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if let geo = service.result {
                    VStack(spacing: 20) {
                        // Details Grid
                        VStack(spacing: 0) {
                            GeoRow(label: "CITY / REGION", value: "\(geo.city ?? "Unknown"), \(geo.region ?? "Unknown")")
                            Divider().background(AppTheme.border.opacity(0.2))
                            GeoRow(label: "COUNTRY", value: "\(geo.country ?? "Unknown") (\(geo.country_code ?? ""))")
                            Divider().background(AppTheme.border.opacity(0.2))
                            GeoRow(label: "ISP / ORGANIZATION", value: geo.connection?.isp ?? geo.connection?.org ?? "Unknown")
                            Divider().background(AppTheme.border.opacity(0.2))
                            GeoRow(label: "ASN", value: "\(geo.connection?.asn ?? 0)")
                            Divider().background(AppTheme.border.opacity(0.2))
                            GeoRow(label: "TIMEZONE", value: geo.timezone?.id ?? "Unknown")
                            Divider().background(AppTheme.border.opacity(0.2))
                            GeoRow(label: "COORDINATES", value: String(format: "%.4f, %.4f", geo.latitude ?? 0, geo.longitude ?? 0))
                        }
                        .background(AppTheme.bgDark.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border.opacity(0.3), lineWidth: 1))
                        
                        // Map
                        ZStack {
                            Map(position: $position) {
                                if let coord = geo.coordinate {
                                    Marker("Location", coordinate: coord)
                                        .tint(AppTheme.neonRed)
                                }
                            }
                            .frame(height: 300)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border.opacity(0.5), lineWidth: 1))
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if let coord = geo.coordinate {
                                            withAnimation {
                                                position = .region(MKCoordinateRegion(
                                                    center: coord,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                                                ))
                                            }
                                        }
                                    }) {
                                        Image(systemName: "scope")
                                            .padding(10)
                                            .background(AppTheme.bgDark)
                                            .cornerRadius(8)
                                            .foregroundStyle(AppTheme.neonCyan)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(12)
                                }
                            }
                        }
                    }
                    .onChange(of: geo.id) {
                        if let coord = geo.coordinate {
                            position = .region(MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                            ))
                        }
                    }
                } else if !service.isFetching {
                    ContentUnavailableView {
                        Label("Visual Locator", systemImage: "map.fill")
                            .font(.largeTitle)
                    } description: {
                        Text("Enter an IP address or domain to map its physical location.")
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(.vertical, 10)
        }
    }
}

struct GeoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.system(.body, design: .monospaced).bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
