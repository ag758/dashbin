import SwiftUI
import SwiftTerm
import AppKit

// MARK: - LocalTerminalView Subclass
// We subclass to intercept data or key events if necessary, though
// the Delegate is usually sufficient for simple title changes.
// For capturing the 'Return' key input specifically to get the line content,
// we can observe the data sent to the PTY or monitor the buffer.
class InteractiveTerminalView: LocalProcessTerminalView {
    var onReturnPressed: ((String) -> Void)?

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        super.send(source: source, data: data)
        
        // Check if data contains a "Return" (CR = 13 or LF = 10)
        // This is a heuristic: when the user types return, it sends a CR to the shell.
        if data.contains(13) {
            // We want to capture the CURRENT line before the shell processes the return
            // However, SwiftTerm's buffer might be updated asynchronously.
            // A safer bet for "what did the user type" is to read the current line from the screen buffer.
            
            // Get the cursor position
            // In SwiftTerm, the cursor position is often tracked within the buffer or via accessor.
            // Based on xterm models, buffer.y is typically the cursor row.
            let cursorY = self.terminal.buffer.y
            
            // Get the line content
            // 'buffer' accesses the screen buffer. 'lines' is an array of screen lines.
            // We need to be careful about accessibility here.
            
            // Note: Accessing terminal internals directly like this relies on SwiftTerm's public API.
            
            if let line = self.terminal.getLine(row: cursorY) {
                // Convert CharData array to String
                var lineString = ""
                for i in 0..<self.terminal.cols {
                    let charData = line[i]
                    let char = charData.getCharacter()
                    if char == Character(UnicodeScalar(0)) { break }
                    lineString.append(char)
                }
                
                // Clean up the prompt. This is tricky because the prompt is part of the line.
                // A simple approach is to return the whole line, or trust the user to copy what they need.
                // For a robust implementation, usually one hooks into the shell zshrc to emit an escape sequence
                // with the command, but per requirements we stick to Swift logic.
                // We will pass the full line for now, filtering empty ones in ViewModel.
                
                onReturnPressed?(lineString)
            }
        }
    }
}

import Combine

// MARK: - SwiftUI Wrapper
struct TerminalViewWrapper: NSViewRepresentable {
    @ObservedObject var viewModel: ShelfViewModel
    
    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = InteractiveTerminalView(frame: .zero)
        
        // Subscribe to commands
        // We store the cancellable in the context coordinator or the view if possible.
        // NSViewRepresentable context.coordinator is best for lifetime management.
        context.coordinator.setupSubscription(terminalView: terminalView)
        
        // Configure typical terminal settings
        terminalView.feed(text: "Welcome to Dashbin!\r\n")
        
        // Start the shell
        // We use /bin/zsh as requested
        let entry = "/bin/zsh"
        // Setup the local process
        // We generally need to run this on appearance, but valid here too.
        // Arguments: empty for default shell behavior
        terminalView.startProcess(executable: entry, args: [], environment: nil, execName: nil)
        
        // Theme (Midnight/Dracula-ish)
        // SwiftTerm has built-in themes but we can set colors manually or check if `apply(theme:)` is available
        // For safety, we'll set basic colors manually mimicking Dracula if standard init doesn't cover it.
        terminalView.nativeBackgroundColor = NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0) // Dark background
        terminalView.nativeForegroundColor = NSColor.white
        
        // Set the callback
        terminalView.onReturnPressed = { commandLine in
            // This runs on the terminal thread, dispatch to main
            DispatchQueue.main.async {
                // Stripping Heuristic:
                // Shell prompts typically end with % or $ or # followed by a space
                // We will look for the LAST occurrence of these common delimiters.
                
                var cleanedCommand = commandLine
                
                // Typical delimiters: "% ", "$ ", "# ", "> "
                // We assume the user creates the command AFTER the last prompt char.
                // NOTE: This might fail if the command itself contains these chars in a way that mimics a prompt,
                // but it's a sufficient heuristic for "ls" or "git status".
                
                if let range = commandLine.range(of: "[%$#>]\\s", options: .regularExpression, range: nil, locale: nil),
                   range.upperBound < commandLine.endIndex {
                    // Heuristic: Find the LAST occurrence of common shell delimiters (%, $, #, >)
                    let delimiters: [Character] = ["%", "$", "#", ">"]
                    var lastIndex: String.Index? = nil
                    
                    for delimiter in delimiters {
                        if let idx = commandLine.lastIndex(of: delimiter) {
                            if lastIndex == nil || idx > lastIndex! {
                                lastIndex = idx
                            }
                        }
                    }
                    
                    if let idx = lastIndex {
                        // Advance past the delimiter
                        let afterDelimiter = commandLine.index(after: idx)
                        if afterDelimiter < commandLine.endIndex {
                            cleanedCommand = String(commandLine[afterDelimiter...])
                        }
                    }
                }
                
                let finalCommand = cleanedCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                if !finalCommand.isEmpty {
                    self.viewModel.addCommand(finalCommand)
                }
            }
        }
        
        return terminalView
    }
    
    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // Layout updates handled automatically by AutoLayout in NSViewRepresentable context mostly
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator {
        var viewModel: ShelfViewModel
        var cancellables = Set<AnyCancellable>()
        
        init(viewModel: ShelfViewModel) {
            self.viewModel = viewModel
        }
        
        func setupSubscription(terminalView: LocalProcessTerminalView) {
            viewModel.commandAction
                .sink { action in
                    switch action {
                    case .run(let cmd):
                        // Send command + newline
                        // We convert String to [UInt8] for send(data:) or use feed(text:) which handles string
                        // BUT feed() goes to the *screen*, send() goes to the *process*.
                        // We must use send() to simulate input.
                        // SwiftTerm send(text:) exists on TerminalView (the superclass).
                        terminalView.send(txt: cmd + "\n")
                        
                    case .paste(let cmd):
                        // Send just command
                        terminalView.send(txt: cmd)
                    }
                }
                .store(in: &cancellables)
        }
    }
}
