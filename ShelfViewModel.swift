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
    
    // MARK: - Search
    @Published var searchText: String = ""
    
    var filteredCommands: [CommandItem] {
        if searchText.isEmpty {
            return commands
        }
        
        let query = searchText.lowercased()
        
        // Filter and sort by score
        // We use a tuple to store score temporarily
        let scored = commands.compactMap { item -> (CommandItem, Double)? in
            if let score = fuzzyScore(item.command, query: query) {
                return (item, score)
            }
            return nil
        }
        
        // Sort descending by score. If tied, keep original order (recency) by using the index difference? 
        // Swift's sort is not stable, so let's try to be stable if we care. 
        // For now, simple sort is fine, but maybe prefer shorter commands for ties?
        return scored.sorted { $0.1 > $1.1 }.map { $0.0 }
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
    
    // Add a unique command to the shelf
    func addCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        DispatchQueue.main.async {
            // Remove existing instances of this command so it can be moved to the top
            if let index = self.commands.firstIndex(where: { $0.command == trimmed }) {
                self.commands.remove(at: index)
            }
            
            // Insert newest at the top
            self.commands.insert(CommandItem(command: trimmed), at: 0)
            
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
