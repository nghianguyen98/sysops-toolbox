
import SwiftUI

@main
struct SysOpsToolboxApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    ContentView()
                }
            }
            .frame(minWidth: 600, minHeight: 400)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .environment(\.isDarkMode, isDarkMode)
        }
    }
}

// Custom Key for passing toggle binding if needed (Or just use AppStorage in ContentView)
struct DarkModeKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var isDarkMode: Bool {
        get { self[DarkModeKey.self] }
        set { self[DarkModeKey.self] = newValue }
    }
}
