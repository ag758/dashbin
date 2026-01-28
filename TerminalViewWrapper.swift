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
    
    override var isFlipped: Bool { true }  // Match terminal's coordinate system
    
    override func draw(_ dirtyRect: NSRect) {
        guard !text.isEmpty else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor
        ]
        
        // Exact baseline alignment as used in SwiftTerm's drawTerminalContents:
        // yOffset = ceil(lineDescent + lineLeading)
        // Draw at NSPoint(x: 0, y: yOffset)
        let descent = CTFontGetDescent(textFont)
        let leading = CTFontGetLeading(textFont)
        let yOffset = ceil(descent + leading)
        
        text.draw(at: NSPoint(x: 0, y: yOffset), withAttributes: attributes)
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
             if let cmd = extractCurrentCommand() {
                 onReturnPressed?(cmd)
             }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.updateGhostText()
        }
    }
    
    private func updateGhostText() {
        guard let viewModel = viewModel else { return }
        
        guard let cmd = extractCurrentCommand() else {
            clearGhost()
            return
        }
        
        if let suggestion = viewModel.suggestion(for: cmd), suggestion != cmd {
            self.currentSuggestion = suggestion
            
            let suffix = String(suggestion.dropFirst(cmd.count))
            if suffix.isEmpty {
                clearGhost()
                return
            }
            
            let cursorCol = self.terminal.buffer.x
            let relativeRow = self.terminal.buffer.y // SwiftTerm's y is relative to yBase
            
            // USE MIRROR to get yDisp and yBase (internal in SwiftTerm)
            // yBase is the start of the current scroll region, yDisp is what's on screen.
            let mirror = Mirror(reflecting: self.terminal.buffer)
            let yDisp = mirror.descendant("_yDisp") as? Int ?? (mirror.descendant("yDisp") as? Int ?? 0)
            let yBase = mirror.descendant("_yBase") as? Int ?? (mirror.descendant("yBase") as? Int ?? 0)
            
            // Correct screen-relative row: relative row + how far the "active base" is from "visual display"
            let visibleRow = relativeRow + (yBase - yDisp)
            
            // Hide if the cursor position is currently scrolled off screen
            if visibleRow < 0 || visibleRow >= self.terminal.rows {
                clearGhost()
                return
            }
            
            let font = self.font
            
            // IDIOMATIC SWIFTTERM CELL CALCULATION:
            // Match computeFontDimensions() logic from AppleTerminalView.swift
            let lineAscent = CTFontGetAscent(font)
            let lineDescent = CTFontGetDescent(font)
            let lineLeading = CTFontGetLeading(font)
            let cellHeight = ceil(lineAscent + lineDescent + lineLeading)
            
            let glyph = font.glyph(withName: "W")
            let cellWidth = font.advancement(forGlyph: glyph).width
            
            // Tweak these values to align ghost text perfectly with terminal text
            let ghostXOffset: CGFloat = 0
            let ghostYOffset: CGFloat = 3.3
            
            // X position: col * cellWidth
            let x = (CGFloat(cursorCol) * cellWidth) + ghostXOffset
            
            // Y position Calculation (Bottom-Up):
            // SwiftTerm's lineOrigin.y = frame.height - cellHeight * CGFloat(row - yDisp + 1)
            let y = self.bounds.height - (cellHeight * CGFloat(visibleRow + 1)) + ghostYOffset
            
            // Size based on text content
            let width = CGFloat(suffix.count) * cellWidth + 50
            
            // Update ghost view
            ghostView.text = suffix
            ghostView.textFont = font
            ghostView.textColor = NSColor.secondaryLabelColor.withAlphaComponent(0.5)
            ghostView.frame = CGRect(x: x, y: y, width: width, height: cellHeight)
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
    
    private func extractCurrentCommand() -> String? {
        let mirror = Mirror(reflecting: self.terminal.buffer)
        let yBase = mirror.descendant("_yBase") as? Int ?? (mirror.descendant("yBase") as? Int ?? 0)
        let cursorY = self.terminal.buffer.y
        let absY = cursorY + yBase
        
        func getCommand(at row: Int) -> String? {
            guard row >= 0 else { return nil }
            
            // Find the start of the command block.
            var startRow = row
            while startRow > 0 {
                guard let line = self.terminal.getLine(row: startRow) else { break }
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
                guard let line = self.terminal.getLine(row: y) else { continue }
                combined.append(line.translateToString(trimRight: true))
            }
            
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
                    let candidate = afterPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !candidate.isEmpty {
                        return candidate
                    }
                }
            }
            
            let trimmedFallback = lineString.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedFallback.isEmpty ? nil : trimmedFallback
        }
        
        // Try the current line first.
        if let cmd = getCommand(at: absY) {
            return cmd
        }
        
        // If current line is empty, the shell might have moved down already. Try the line above.
        return getCommand(at: absY - 1)
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
