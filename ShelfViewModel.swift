import Foundation
import AppKit

struct CommandItem: Identifiable, Hashable, Codable {
    var id = UUID()
    let command: String
    var timestamp: Date = Date()
}

import Combine

class ShelfViewModel: ObservableObject {
    @Published var commands: [CommandItem] = []
    
    private var persistenceURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = appSupport.appendingPathComponent("dashbin")
        // Ensure folder exists
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("history.json")
    }
    
    init() {
        loadCommands()
    }
    
    private let maxCommandHistory = 5000
    
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
                
                // Enforce limit
                if self.commands.count > self.maxCommandHistory {
                    self.commands = Array(self.commands.prefix(self.maxCommandHistory))
                }
                
                self.saveCommands()
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
    
    // MARK: - Persistence
    
    private func loadCommands() {
        guard let url = persistenceURL,
              let data = try? Data(contentsOf: url) else { return }
        
        do {
            let decoder = JSONDecoder()
            // Optional: handle date decoding strategy if needed, default is usually fine for TimeInterval
            // command items use default Date encoding? Let's assume standard.
            let items = try decoder.decode([CommandItem].self, from: data)
            self.commands = items
        } catch {
            print("Failed to load history: \(error)")
        }
    }
    
    private func saveCommands() {
        guard let url = persistenceURL else { return }
        
        do {
            let encoder = JSONEncoder()
            // Pretty print for debugging ease, optional
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(commands)
            try data.write(to: url)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}
