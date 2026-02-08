import SwiftUI

@main
struct DashbinApp: App {
    init() {
        // Ensure the app appears in the Dock
        NSApplication.shared.setActivationPolicy(.regular)
        
        // Load and set the app icon from assets
        // Use the 128x128@2x (256px) icon which is appropriate for Dock display
        let iconFileName = "icon_128x128@2x.png"
        let possiblePaths = [
            // SPM command-line build path
            Bundle.module.resourcePath.map { ($0 as NSString).appendingPathComponent("Assets.xcassets/AppIcon.appiconset/\(iconFileName)") },
            // Try Bundle.main for Xcode
            Bundle.main.resourcePath.map { ($0 as NSString).appendingPathComponent("Assets.xcassets/AppIcon.appiconset/\(iconFileName)") },
            // Source directory fallback (works during development)
            (#file as NSString).deletingLastPathComponent + "/Assets.xcassets/AppIcon.appiconset/\(iconFileName)"
        ].compactMap { $0 }
        
        var iconLoaded = false
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path),
               let image = NSImage(contentsOfFile: path) {
                print("Successfully loaded app icon from: \(path)")
                NSApplication.shared.applicationIconImage = image
                iconLoaded = true
                break
            }
        }
        
        if !iconLoaded {
            print("Failed to load app icon. Tried paths:")
            for path in possiblePaths {
                let exists = FileManager.default.fileExists(atPath: path)
                print("  [\(exists ? "EXISTS" : "MISSING")] \(path)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        //.windowStyle(.hiddenTitleBar) // Commented out to debug visibility
        .commands {
            // Optional: Add menu commands here if needed
            SidebarCommands() // Enable sidebar toggling
        }
    }
}
