import SwiftUI

@main
struct DashbinApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        
        // This loads the icon automatically from your Assets.xcassets
        if let icon = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = icon
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        //.windowStyle(.hiddenTitleBar) 
        .commands {
            // Optional: Add menu commands here if needed
            SidebarCommands() // Enable sidebar toggling
        }
    }
}
