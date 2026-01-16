import SwiftUI

@main
struct DashbinApp: App {
    init() {
        // Ensure the app appears in the Dock
        NSApplication.shared.setActivationPolicy(.regular)
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
