import Foundation
import AppKit

struct CommandItem: Identifiable, Hashable {
    let id = UUID()
    let command: String
    let timestamp: Date = Date()
}

import Combine

class ShelfViewModel: ObservableObject {
    @Published var commands: [CommandItem] = []
    
    // Action stream for Terminal to listen to
    enum TerminalAction {
        case run(String)
        case paste(String)
    }
    let commandAction = PassthroughSubject<TerminalAction, Never>()
    
    // Add a unique command to the shelf
    func addCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // For "unique command strings" per requirements:
        if !commands.contains(where: { $0.command == trimmed }) {
            DispatchQueue.main.async {
                self.commands.insert(CommandItem(command: trimmed), at: 0)
            }
        }
    }
    
    // Copy to clipboard (Legacy/System clipboard)
    func copyCommand(_ command: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(command, forType: .string)
    }
    
    // Triggers
    func triggerRun(_ command: String) {
        // Run button: Copy + Paste + Run
        copyCommand(command)
        commandAction.send(.run(command))
    }
    
    func triggerPaste(_ command: String) {
        commandAction.send(.paste(command))
    }
}
