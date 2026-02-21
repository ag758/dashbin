import Foundation
import AppKit

struct CommandItem: Identifiable, Hashable, Codable {
    var id = UUID()
    let command: String
    var timestamp: Date = Date()
    var isPinned: Bool? = false
}

struct CommandFolder: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var commands: [CommandItem] = []
}

import Combine

class ShelfViewModel: ObservableObject {
    @Published var commands: [CommandItem] = []
    @Published var folders: [CommandFolder] = []
    
    private var persistenceURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = appSupport.appendingPathComponent("dashbin")
        // Ensure folder exists
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("history.json")
    }

    private var foldersURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = appSupport.appendingPathComponent("dashbin")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("folders.json")
    }
    
    init() {
        loadCommands()
        loadFolders()
    }
    
    // MARK: - Search
    @Published var searchText: String = ""
    
    var filteredCommands: [CommandItem] {
        let baseList: [CommandItem]
        
        if searchText.isEmpty {
            baseList = commands
        } else {
            let query = searchText.lowercased()
            
            // Filter and sort by score
            // We use a tuple to store score temporarily
            let scored = commands.compactMap { item -> (CommandItem, Double)? in
                if let score = fuzzyScore(item.command, query: query) {
                    return (item, score)
                }
                return nil
            }
            
            baseList = scored.sorted { $0.1 > $1.1 }.map { $0.0 }
        }
        
        // Return baseList directly, folders handle groupings now
        return baseList
    }
    
    var suggestedCommand: String? {
        return suggestion(for: searchText)
    }
    
    func suggestion(for partial: String) -> String? {
        guard !partial.isEmpty else { return nil }
        
        // We can optimize this by not sorting everything if we just want the best prefix match.
        // But reusing filtered logic ensures consistency.
        // However, 'filteredCommands' relies on 'searchText'.
        // We should replicate the logic for an arbitrary query safely.
        
        let query = partial.lowercased()
        
        // Find best match in commands
        // We prioritize prefix matches for autocomplete
        // Simple scan:
        for item in commands {
            let cmdLower = item.command.lowercased()
            if cmdLower.hasPrefix(query) {
                return item.command
            }
        }
        return nil
    }
    
    // Simple Fuzzy Match scoring
    // Returns nil if no match, or a score > 0 (higher is better)
    private func fuzzyScore(_ candidate: String, query: String) -> Double? {
        // Quick check: if query is longer than candidate, it can't match
        if query.count > candidate.count { return nil }
        
        let candidateLower = candidate.lowercased()
        
        // If query is empty, technically it matches everything, but we handle that upstream.
        if query.isEmpty { return 1.0 }
        
        var score: Double = 0.0
        var queryIndex = query.startIndex
        var candidateIndex = candidateLower.startIndex
        var consecutiveMatches = 0
        
        // First character index match bonus
        var firstMatchIndex: Int? = nil
        
        while queryIndex < query.endIndex && candidateIndex < candidateLower.endIndex {
            let queryChar = query[queryIndex]
            
            // Find next occurrence of queryChar in candidate
            // We search from candidateIndex onwards
            var found = false
            var scanIndex = candidateIndex
            
            while scanIndex < candidateLower.endIndex {
                if candidateLower[scanIndex] == queryChar {
                    found = true
                    
                    // Scoring logic
                    
                    // 1. Base match
                    score += 10.0
                    
                    // 2. Consecutive match bonus
                    if scanIndex == candidateIndex {
                        consecutiveMatches += 1
                        score += (Double(consecutiveMatches) * 5.0) // snowball effect
                    } else {
                        consecutiveMatches = 0
                    }
                    
                    // 3. Start of string bonus
                    if scanIndex == candidateLower.startIndex {
                        score += 20.0
                    }
                    
                    // 4. Index penalty (earlier is better)
                    // We simply subtract a small amount based on distance
                    let distance = candidateLower.distance(from: candidateLower.startIndex, to: scanIndex)
                    if firstMatchIndex == nil { firstMatchIndex = distance }
                    
                    score -= Double(distance) * 0.1
                    
                    // Advance indices
                    candidateIndex = candidateLower.index(after: scanIndex)
                    queryIndex = query.index(after: queryIndex)
                    break
                }
                scanIndex = candidateLower.index(after: scanIndex)
            }
            
            if !found {
                return nil // Character sequence not found
            }
        }
        
        // If we finished the query, it's a match
        return queryIndex == query.endIndex ? score : nil
    }
    
    private let maxCommandHistory = 5000
    
    // Action stream for Terminal to listen to
    enum TerminalAction {
        case run(String)
        case paste(String)
    }
    let commandAction = PassthroughSubject<TerminalAction, Never>()
    
    func createFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        DispatchQueue.main.async {
            self.folders.insert(CommandFolder(name: trimmed), at: 0)
            self.saveFolders()
        }
    }
    
    func deleteFolder(id: UUID) {
        DispatchQueue.main.async {
            self.folders.removeAll { $0.id == id }
            self.saveFolders()
        }
    }
    
    func renameFolder(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        DispatchQueue.main.async {
            if let idx = self.folders.firstIndex(where: { $0.id == id }) {
                self.folders[idx].name = trimmed
                self.saveFolders()
            }
        }
    }
    
    func addCommandToFolder(_ command: CommandItem, folderId: UUID) {
        DispatchQueue.main.async {
            if let idx = self.folders.firstIndex(where: { $0.id == folderId }) {
                if !self.folders[idx].commands.contains(where: { $0.command == command.command }) {
                    var newItem = command
                    newItem.id = UUID()
                    self.folders[idx].commands.insert(newItem, at: 0)
                    self.saveFolders()
                }
            }
        }
    }
    
    func removeCommandFromFolder(commandId: UUID, folderId: UUID) {
        DispatchQueue.main.async {
            if let idx = self.folders.firstIndex(where: { $0.id == folderId }) {
                self.folders[idx].commands.removeAll { $0.id == commandId }
                self.saveFolders()
            }
        }
    }

    // Delete a command by ID
    func deleteCommand(id: UUID) {
        if let index = commands.firstIndex(where: { $0.id == id }) {
            commands.remove(at: index)
            saveCommands()
        }
    }

    // Add a unique command to the shelf
    func addCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        DispatchQueue.main.async {
            var existingIsPinned = false
            
            // Remove existing instances of this command so it can be moved to the top
            if let index = self.commands.firstIndex(where: { $0.command == trimmed }) {
                existingIsPinned = self.commands[index].isPinned ?? false
                self.commands.remove(at: index)
            }
            
            // Insert newest at the top, preserving pinned status if it was already pinned
            var newItem = CommandItem(command: trimmed)
            newItem.isPinned = existingIsPinned
            self.commands.insert(newItem, at: 0)
            
            // Enforce limit
            if self.commands.count > self.maxCommandHistory {
                self.commands = Array(self.commands.prefix(self.maxCommandHistory))
            }
            
            self.saveCommands()
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
    
    private func loadFolders() {
        guard let url = foldersURL,
              let data = try? Data(contentsOf: url) else { return }
        do {
            self.folders = try JSONDecoder().decode([CommandFolder].self, from: data)
        } catch {
            print("Failed to load folders: \(error)")
        }
    }
    
    private func saveFolders() {
        guard let url = foldersURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(folders)
            try data.write(to: url)
        } catch {
            print("Failed to save folders: \(error)")
        }
    }
    
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
