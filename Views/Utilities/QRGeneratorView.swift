import SwiftUI
import CoreImage.CIFilterBuiltins
import Combine
import UniformTypeIdentifiers

class QRViewModel: ObservableObject {
    @Published var selectedTab: Int = 0 // 0: Text, 1: WiFi
    
    // Text Mode
    @Published var textContent: String = "https://example.com"
    
    // WiFi Mode
    @Published var wifiSSID: String = ""
    @Published var wifiPass: String = ""
    @Published var wifiHidden: Bool = false
    @Published var wifiType: WiFiEncryption = .wpa
    
    enum WiFiEncryption: String, CaseIterable, Identifiable {
        case wpa = "WPA/WPA2"
        case wep = "WEP"
        case none = "None"
        var id: String { self.rawValue }
    }
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var finalString: String {
        if selectedTab == 0 {
            return textContent
        } else {
            // WIFI:S:MySSID;T:WPA;P:MyPass;;
            // Special chars in SSID/Pass should optionally be escaped, but basic format is usually enough.
            // Format: WIFI:T:WPA;S:mynet;P:mypass;;
            var str = "WIFI:"
            
            // Type
            switch wifiType {
            case .wpa: str += "T:WPA;"
            case .wep: str += "T:WEP;"
            case .none: str += "T:nopass;"
            }
            
            // SSID
            str += "S:\(wifiSSID);"
            
            // Password
            if wifiType != .none && !wifiPass.isEmpty {
                str += "P:\(wifiPass);"
            }
            
            // Hidden
            if wifiHidden {
                str += "H:true;"
            }
            
            str += ";"
            return str
        }
    }
    
    func generateQRCode() -> NSImage? {
        let stringData = finalString.data(using: .utf8) ?? Data()
        filter.message = stringData
        
        if let outputImage = filter.outputImage {
            // Scale up (Nearest Neighbor) to keep it crisp
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            let rep = NSCIImageRep(ciImage: scaledImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            return nsImage
        }
        return nil
    }
}

struct QRGeneratorView: View {
    @StateObject private var viewModel = QRViewModel()
    @State private var generatedImage: NSImage?
    
    var body: some View {
        ToolCard(title: "QR Code Generator", icon: "qrcode") {
            HStack(spacing: 0) {
                // LEFT: Config
                VStack(spacing: 0) {
                    Picker("", selection: $viewModel.selectedTab) {
                        Text("Text / URL").tag(0)
                        Text("WiFi Config").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if viewModel.selectedTab == 0 {
                                // Text Mode
                                InputField(label: "Content", text: $viewModel.textContent)
                            } else {
                                // WiFi Mode
                                InputField(label: "Network Name (SSID)", text: $viewModel.wifiSSID)
                                
                                Picker("Security", selection: $viewModel.wifiType) {
                                    ForEach(QRViewModel.WiFiEncryption.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                if viewModel.wifiType != .none {
                                    InputField(label: "Password", text: $viewModel.wifiPass)
                                }
                                
                                Toggle("Hidden Network", isOn: $viewModel.wifiHidden)
                            }
                        }
                        .padding()
                    }
                }
                .frame(width: 350)
                
                Divider().background(AppTheme.border)
                
                // RIGHT: Preview
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxHeight: 400)
                            .padding()
                        
                        if let img = viewModel.generateQRCode() {
                            Image(nsImage: img)
                                .resizable()
                                .interpolation(.none) // Keep pixels sharp
                                .scaledToFit()
                                .frame(maxHeight: 360)
                                .padding()
                        }
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if let img = viewModel.generateQRCode() {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.writeObjects([img])
                            }
                        }) {
                            Label("Copy Image", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: {
                            saveImage()
                        }) {
                            Label("Save PNG", systemImage: "square.and.arrow.down")
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.bgDark.opacity(0.5))
            }
            .frame(height: 500)
        }
    }
    
    private func saveImage() {
        guard let img = viewModel.generateQRCode() else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save QR Code"
        savePanel.message = "Choose a location to save your QR code."
        savePanel.nameFieldStringValue = "qr_code.png"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let tiffData = img.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: url)
                }
            }
        }
    }
}
