import SwiftUI
import SwiftTerm
import AppKit

// MARK: - LocalTerminalView Subclass
// We subclass to intercept data or key events if necessary, though
// the Delegate is usually sufficient for simple title changes.
// For capturing the 'Return' key input specifically to get the line content,
// we can observe the data sent to the PTY or monitor the buffer.
// Custom view for ghost text that draws directly without layout manager overhead
class GhostTextView: NSView {
    var text: String = "" {
        didSet { needsDisplay = true }
    }
    var textFont: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    var textColor: NSColor = NSColor.secondaryLabelColor.withAlphaComponent(0.5)
    
    var cursorCol: Int = 0
    var terminalCols: Int = 80
    var cellWidth: CGFloat = 0
    var cellHeight: CGFloat = 0
    
    override var isFlipped: Bool { true }  // Match terminal's coordinate system
    
    override func draw(_ dirtyRect: NSRect) {
        guard !text.isEmpty, cellWidth > 0, cellHeight > 0 else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor
        ]
        
        // Natural vertical offset to match terminal text baseline.
        // Usually approximately ceil(leading / 2.0), but 1.5 is a solid default for SF Mono in this context.
        let yOffset = CGFloat(1.5)
        
        let availableOnFirstLine = max(0, terminalCols - cursorCol)
        
        // Replace spaces with non-breaking spaces to ensure leading whitespace is visible/drawn
        let displayText = text.replacingOccurrences(of: " ", with: "\u{00a0}")
        var currentText = displayText
        var currentRow: Int = 0
        
        // Draw first line starting at cursorCol
        let firstLinePart = String(currentText.prefix(availableOnFirstLine))
        firstLinePart.draw(at: NSPoint(x: CGFloat(cursorCol) * cellWidth, y: yOffset), withAttributes: attributes)
        
        currentText = String(currentText.dropFirst(availableOnFirstLine))
        
        // Draw subsequent lines starting at column 0
        while !currentText.isEmpty {
            currentRow += 1
            let linePart = String(currentText.prefix(terminalCols))
            let yPos = CGFloat(currentRow) * cellHeight + yOffset
            linePart.draw(at: NSPoint(x: 0, y: yPos), withAttributes: attributes)
            currentText = String(currentText.dropFirst(terminalCols))
        }
    }
}

class InteractiveTerminalView: LocalProcessTerminalView {
    var onReturnPressed: ((String) -> Void)?
    var viewModel: ShelfViewModel?
    
    // Custom ghost text view for pixel-perfect alignment
    private let ghostView = GhostTextView()
    private var currentSuggestion: String?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupGhostView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGhostView()
    }
    
    private func setupGhostView() {
        ghostView.wantsLayer = true
        ghostView.layer?.backgroundColor = NSColor.clear.cgColor
        self.addSubview(ghostView)
    }
    
    override func layout() {
        super.layout()
        updateGhostText()
    }

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        // Handle TAB for autocomplete (keycode 9)
        if let first = data.first, first == 9 {
            if let suggestion = currentSuggestion, let cmd = extractCurrentCommand() {
                if suggestion.hasPrefix(cmd) {
                    let suffix = String(suggestion.dropFirst(cmd.count))
                    if !suffix.isEmpty {
                        self.send(txt: suffix)
                        self.currentSuggestion = nil
                        ghostView.text = ""
                        ghostView.needsDisplay = true
                        return
                    }
                }
            }
        }
        
        super.send(source: source, data: data)
        
        if data.contains(13) {
             if let cmd = extractCurrentCommand(restrictToCursor: false) {
                 onReturnPressed?(cmd)
             }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.updateGhostText()
        }
    }
    
    private func updateGhostText() {
        guard let viewModel = viewModel else { return }
        
        guard let cmd = extractCurrentCommand(restrictToCursor: true) else {
            clearGhost()
            return
        }
        
        if let suggestion = viewModel.suggestion(for: cmd.trimmingCharacters(in: .whitespacesAndNewlines)), suggestion != cmd {
            self.currentSuggestion = suggestion
            
            // We need to figure out what part of the suggestion to show.
            // If the user typed "cd ", and suggestion is "cd ~/desktop",
            // cmd is "cd ". suggestion is "cd ~/desktop".
            // we want to show "~/desktop" starting at cursorCol.
            
            // However, our suggestion search might match "cd" to "cd ~/desktop" 
            // but the user typed invalid spaces "cd  ".
            // So we need to be careful.
            
            // Simple logic:
            // 1. check if suggestion technically starts with trimmed cmd?
            // Already done in viewModel.suggestion usually.
            
            // 2. We want to draw the REST of the suggestion.
            // But if the user typed extra spaces that are NOT in the suggestion, we can't really suggest.
            // E.g. user typed "git  ", suggestion "git status". 
            // The user has gone off-path. 
            
            // Let's rely on string prefix check.
            if !suggestion.hasPrefix(cmd) {
                clearGhost()
                return
            }
            
            let suffix = String(suggestion.dropFirst(cmd.count))
            if suffix.isEmpty {
                clearGhost()
                return
            }
            
            let cursorCol = self.terminal.buffer.x
            let relativeRow = self.terminal.buffer.y
            
            let mirror = Mirror(reflecting: self.terminal.buffer)
            let yDisp = mirror.descendant("_yDisp") as? Int ?? (mirror.descendant("yDisp") as? Int ?? 0)
            let yBase = mirror.descendant("_yBase") as? Int ?? (mirror.descendant("yBase") as? Int ?? 0)
            
            let visibleRow = relativeRow + (yBase - yDisp)
            
            if visibleRow < 0 || visibleRow >= self.terminal.rows {
                clearGhost()
                return
            }
            
            let font = self.font
            let lineAscent = CTFontGetAscent(font)
            let lineDescent = CTFontGetDescent(font)
            let lineLeading = CTFontGetLeading(font)
            let cellHeight = ceil(lineAscent + lineDescent + lineLeading)
            
            let glyph = font.glyph(withName: "W")
            let cellWidth = font.advancement(forGlyph: glyph).width
            
            // Calculate wrapping to determine height
            let availableOnFirstLine = max(0, self.terminal.cols - cursorCol)
            var neededRows = 1
            if suffix.count > availableOnFirstLine {
                let remaining = suffix.count - availableOnFirstLine
                neededRows += Int(ceil(Double(remaining) / Double(self.terminal.cols)))
            }
            
            // Tweak this value to align ghost text perfectly. 
            // Increasing this moves the text UP. 
            let ghostYOffset: CGFloat = 1.5
            
            // X position: 0 (view handles its own horizontal offsets)
            let x: CGFloat = 0
            
            // Y position calculation (bottom-up coordinate system)
            // lineBottom is the y-coordinate of the bottom edge of the current cursor row.
            let lineBottom = self.bounds.height - (cellHeight * CGFloat(visibleRow + 1))
            
            // The first line of ghost text should align perfectly with the current cursor row.
            // Terminal row occupies [lineBottom, lineBottom + cellHeight].
            // To grow downwards, the view's origin.y (bottom) must be shifted down.
            let height = CGFloat(neededRows) * cellHeight
            let y = lineBottom + cellHeight - height + ghostYOffset
            
            let width = self.bounds.width
            
            ghostView.cursorCol = cursorCol
            ghostView.terminalCols = self.terminal.cols
            ghostView.cellWidth = cellWidth
            ghostView.cellHeight = cellHeight
            
            ghostView.text = suffix
            ghostView.textFont = font
            ghostView.textColor = NSColor.secondaryLabelColor.withAlphaComponent(0.5)
            ghostView.frame = CGRect(x: x, y: y, width: width, height: height)
            ghostView.needsDisplay = true
             
        } else {
            clearGhost()
        }
    }
    
    private func clearGhost() {
        currentSuggestion = nil
        ghostView.text = ""
        ghostView.needsDisplay = true
    }
    
    private func extractCurrentCommand(restrictToCursor: Bool = false) -> String? {
        let cursorX = self.terminal.buffer.x
        let cursorY = self.terminal.buffer.y
        let mirror = Mirror(reflecting: self.terminal.buffer)
        let yBase = mirror.descendant("_yBase") as? Int ?? (mirror.descendant("yBase") as? Int ?? 0)
        let absY = cursorY + yBase
        
        func getCommand(at row: Int) -> String? {
            guard row >= 0 else { return nil }
            
            // Find the start of the command block.
            var startRow = row
            while startRow > 0 {
                guard let line = self.terminal.getScrollInvariantLine(row: startRow) else { break }
                let lineMirror = Mirror(reflecting: line)
                let isWrapped = lineMirror.descendant("isWrapped") as? Bool ?? false
                if isWrapped {
                    startRow -= 1
                } else {
                    break
                }
            }
            
            var combined = ""
            for y in startRow...row {
                guard let line = self.terminal.getScrollInvariantLine(row: y) else { continue }
                
                // If we restrict to cursor, we want RAW text (no right trim) so we can slice exactly
                // Otherwise we trim right (default/legacy behavior)
                var lineStr = line.translateToString(trimRight: !restrictToCursor)
                
                if restrictToCursor && y == absY {
                     // Check bounds and truncate to cursor position
                     // This ensures we don't accidentally pick up "deleted" characters if the buffer hasn't cleared them yet
                     let safeCount = min(cursorX, lineStr.count)
                     lineStr = String(lineStr.prefix(safeCount))
                }
                
                combined.append(lineStr)
            }
            
            // If restrictToCursor is true, combined now ends exactly at cursor.
            
            let lineString = combined
            if lineString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return nil
            }
            
            // Flexible regex for prompt stripping
            let pattern = #".*[%$#>❯➜\]\)] *"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = lineString as NSString
                let matches = regex.matches(in: lineString, options: [], range: NSRange(location: 0, length: nsString.length))
                if let lastMatch = matches.last {
                    let afterPrompt = nsString.substring(from: lastMatch.range.location + lastMatch.range.length)
                    // Trim only leading whitespace to preserve trailing spaces (cursor position)
                    var candidate = afterPrompt
                    if let range = candidate.range(of: "^\\s+", options: .regularExpression) {
                        candidate.removeSubrange(range)
                    }
                    
                    // If we found a prompt but there's nothing after it, this is an empty command
                    return candidate.isEmpty ? nil : candidate
                }
            }
            
            // Fallback only if no prompt was detected at all
            var trimmedFallback = lineString
            if let range = trimmedFallback.range(of: "^\\s+", options: .regularExpression) {
                trimmedFallback.removeSubrange(range)
            }
            return trimmedFallback.isEmpty ? nil : trimmedFallback
        }
        
        // Try the current line first.
        if let cmd = getCommand(at: absY) {
            return cmd
        }
        
        // If current line is empty, the shell might have moved down already. Try the line above.
        // We only use fallback for full extraction (e.g. Enter pressed), not ghost text
        if !restrictToCursor {
            return getCommand(at: absY - 1)
        }
        
        return nil
    }
}

import Combine

// MARK: - SwiftUI Wrapper
struct TerminalViewWrapper: NSViewRepresentable {
    @ObservedObject var viewModel: ShelfViewModel
    
    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = InteractiveTerminalView(frame: .zero)
        terminalView.viewModel = viewModel
        
        // Hide weird scrollbar glitch by subclassing or configuring the scrollview
        // Since LocalProcessTerminalView is an NSView, it might be embedded in a ScrollView by SwiftTerm,
        // OR it inherits from NSScrollView. Let's check inheritance.
        // LocalProcessTerminalView -> TerminalView -> NSView.
        // It seems TerminalView manages its own scrollbar OR it expects to be in one.
        // Actually, looking at SwiftTerm docs/source, TerminalView usually manages drawing.
        // If there is a "glitching scrollbar", it might be an NSScrollView wrapping it.
        // BUT, SwiftTerm often includes its own scrollbar logic if using the Mac/iOS kit properly.
        
        // Let's try to disable the scroller on the storage if possible, or just the view behavior.
        // TerminalView.configureNative(wrapper: ...)
        
        // Actually, for Mac, TerminalView is just a view. If we see a scrollbar it is likely
        // because it is wrapped in an NSScrollView in strict AppKit mode or we put it there.
        // Re-reading SwiftTerm Mac structure:
        // public open class TerminalView: NSView, NSTextInputClient, NSUserInterfaceValidations
        
        // If the user sees a glitchy scrollbar, it might be the default NSScroller.
        // We can try to force it off if it is indeed an NSScrollView subclass (which it isn't directly),
        // or if it HAS a scrollview.
        
        // Wait, looking at typical usage:
        // terminalView.enclosingScrollView?.hasVerticalScroller = false
        // But we are in makeNSView, so it isn't in the hierarchy yet.
        
        // Let's try a different approach. We can wrap it in an NSScrollView ourselves and hide it, 
        // OR simply trust that we can configure it later. 
        
        // However, the error said `hasVerticalScroller` is not a member.
        // This confirms it is NOT an NSScrollView.
        
        // If the user sees a scrollbar, maybe they are referring to the SwiftTerm internal one?
        // terminalView.scrollbarVisible = false ? No.
        
        // Let's try searching for a scrollbar property in the library logic usually.
        // `terminalView.scroller` exists in some versions?
        
        // Correct fix for standard NSView glitchiness is often just ensuring layers are backed.
        terminalView.wantsLayer = true
        
        // Since `scroller` is private, we can't hide it directly on the TerminalView.
        // The most robust way to hide scrollbars in AppKit is to embed the view in a new NSScrollView
        // that is configured to hide them.
        // However, standard TerminalView usage in SwiftTerm usually handles its own scrolling.
        // If we want to hide it, the best we can do without subclassing inside the library is
        // to look for subviews that are NSScroller and hide them.
        
        for subview in terminalView.subviews {
            if let scroller = subview as? NSScroller {
                scroller.isHidden = true
            }
        }
        
        // Subscribe to commands
        // We store the cancellable in the context coordinator or the view if possible.
        // NSViewRepresentable context.coordinator is best for lifetime management.
        context.coordinator.setupSubscription(terminalView: terminalView)
        
        // Configure shell environment variables with explicit user context
        var env = ProcessInfo.processInfo.environment
        let userName = NSUserName()
        let homeDir = NSHomeDirectory()
        
        env["USER"] = userName
        env["LOGNAME"] = userName
        env["HOME"] = homeDir
        env["TERM"] = "xterm-256color"
        env["SHELL"] = "/bin/zsh"
        
        // Prioritize system paths in PATH to ensure commands like sudo/ls are found
        let systemPaths = ["/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        let currentPath = env["PATH"] ?? ""
        let existingComponents = currentPath.split(separator: ":").map(String.init)
        // Filter out system paths from existing to avoid duplicates, then prepend
        let filteredComponents = existingComponents.filter { !systemPaths.contains($0) }
        let newPath = (systemPaths + filteredComponents).joined(separator: ":")
        env["PATH"] = newPath
        
        // Convert environment dictionary to array of strings (KEY=VALUE) as expected by startProcess
        let envStrings = env.map { "\($0.key)=\($0.value)" }
        
        // Use /usr/bin/login to ensure a proper TTY session and permissions (fixes sudo issues)
        // -f: Force login as user (no password needed for current user)
        // -p: Preserve environment variables
        // This implicitly launches the default shell (zsh) with the context initialized
        terminalView.startProcess(executable: "/usr/bin/login", args: ["-f", "-p", userName], environment: envStrings)
        
        // Theme (Dashbin Modern)
        // Background: Deep, rich dark blue/grey
        terminalView.nativeBackgroundColor = NSColor(hex: "1E1E22") 
        terminalView.nativeForegroundColor = NSColor(hex: "F8F8F2")
        // terminalView.nativeCursorColor = NSColor(hex: "00F5FF") // Accent Cyan
        // terminalView.nativeSelectionColor = NSColor(hex: "44475A")
        
        // ANSI Colors (0-15)
        // Tuned for high contrast and modern aesthetics
        let ansiColors: [NSColor] = [
            NSColor(hex: "21222C"), // Black
            NSColor(hex: "FF5555"), // Red (Bright/Salmon for readability)
            NSColor(hex: "50FA7B"), // Green
            NSColor(hex: "F1FA8C"), // Yellow
            NSColor(hex: "BD93F9"), // Blue (Dracula-ish purple-blue)
            NSColor(hex: "FF79C6"), // Magenta
            NSColor(hex: "8BE9FD"), // Cyan
            NSColor(hex: "F8F8F2"), // White
            
            NSColor(hex: "6272A4"), // Bright Black
            NSColor(hex: "FF6E6E"), // Bright Red
            NSColor(hex: "69FF94"), // Bright Green
            NSColor(hex: "FFFFA5"), // Bright Yellow
            NSColor(hex: "D6ACFF"), // Bright Blue
            NSColor(hex: "FF92DF"), // Bright Magenta
            NSColor(hex: "A4FFFF"), // Bright Cyan
            NSColor(hex: "FFFFFF")  // Bright White
        ]
        
        func toTermColor(_ color: NSColor) -> SwiftTerm.Color {
            guard let converted = color.usingColorSpace(.sRGB) else { return SwiftTerm.Color(red: 0, green: 0, blue: 0) }
            return SwiftTerm.Color(red: UInt16(converted.redComponent * 65535),
                                   green: UInt16(converted.greenComponent * 65535),
                                   blue: UInt16(converted.blueComponent * 65535))
        }

        terminalView.installColors(ansiColors.map(toTermColor))
        
        // Set the callback
        // Note: extractCurrentCommand() already strips the prompt, so we just use the command directly
        terminalView.onReturnPressed = { commandLine in
            DispatchQueue.main.async {
                let finalCommand = commandLine.trimmingCharacters(in: .whitespacesAndNewlines)
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
                        terminalView.send(txt: cmd + "\n")
                        
                    case .paste(let cmd):
                        terminalView.send(txt: cmd)
                    }
                }
                .store(in: &cancellables)
        }
    }
}

extension NSColor {
    convenience init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            self.init(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
            return
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            srgbRed: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
