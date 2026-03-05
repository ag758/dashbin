import SwiftUI
import Combine
import AppKit

// MARK: - Theme Definition

struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String       // SF Symbol name
    
    // -- Background & Surfaces --
    let base: String        // Deepest background
    let surface: String     // Panel backgrounds
    let elevated: String    // Hover / card state
    let terminalBg: String  // Terminal background
    
    // -- Borders --
    let border: String      // Default border stroke
    let borderActive: String // Focused border
    
    // -- Text --
    let textPrimary: String   // Main text
    let textSecondary: String // Muted / secondary text
    let textMuted: String     // Dimmed / placeholder
    
    // -- Accents --
    let accent: String       // Primary brand accent (buttons, active states)
    let accentSecondary: String // Secondary accent
    let accentTertiary: String  // Tertiary accent (folder icons, warnings)
    
    // -- Feedback --
    let success: String     // Copied, success states
    let info: String        // Running, info states
    
    // -- Aura glows (background mesh gradient) --
    let aura1: String       // Top-left glow
    let aura2: String       // Bottom-right glow
    let aura3: String       // Bottom-center glow
    
    // -- Terminal ANSI colors --
    let ansiBlack: String
    let ansiRed: String
    let ansiGreen: String
    let ansiYellow: String
    let ansiBlue: String
    let ansiMagenta: String
    let ansiCyan: String
    let ansiWhite: String
    let ansiBrightBlack: String
    let ansiBrightRed: String
    let ansiBrightGreen: String
    let ansiBrightYellow: String
    let ansiBrightBlue: String
    let ansiBrightMagenta: String
    let ansiBrightCyan: String
    let ansiBrightWhite: String
    
    // -- Terminal foreground --
    let terminalFg: String
    
    // -- Light mode flag --
    let isLight: Bool
}

// MARK: - Built-in Themes

extension AppTheme {

    // ── 1. Dark Modern (VS Code Default, updated accent) ──
    static let darkModern = AppTheme(
        id: "dark_modern",
        name: "Dark Modern",
        icon: "rectangle.fill.on.rectangle.fill",
        base: "1F1F1F",
        surface: "252526",
        elevated: "2D2D2D",
        terminalBg: "1E1E1E",
        border: "3C3C3C",
        borderActive: "505050",
        textPrimary: "CCCCCC",
        textSecondary: "9D9D9D",
        textMuted: "6A6A6A",
        accent: "4A6CF7",
        accentSecondary: "7B93FF",
        accentTertiary: "DCDCAA",
        success: "6A9955",
        info: "4A6CF7",
        aura1: "4A6CF7",
        aura2: "7B93FF",
        aura3: "DCDCAA",
        ansiBlack: "1E1E1E",
        ansiRed: "F44747",
        ansiGreen: "6A9955",
        ansiYellow: "DCDCAA",
        ansiBlue: "569CD6",
        ansiMagenta: "C586C0",
        ansiCyan: "4EC9B0",
        ansiWhite: "D4D4D4",
        ansiBrightBlack: "808080",
        ansiBrightRed: "F44747",
        ansiBrightGreen: "B5CEA8",
        ansiBrightYellow: "DCDCAA",
        ansiBrightBlue: "9CDCFE",
        ansiBrightMagenta: "C586C0",
        ansiBrightCyan: "4EC9B0",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "CCCCCC",
        isLight: false
    )

    // ── 2. Light Modern (VS Code Default, updated accent) ──
    static let lightModern = AppTheme(
        id: "light_modern",
        name: "Light Modern",
        icon: "rectangle.on.rectangle",
        base: "F3F3F3",
        surface: "FFFFFF",
        elevated: "E8E8E8",
        terminalBg: "FFFFFF",
        border: "CECECE",
        borderActive: "A0A0A0",
        textPrimary: "1E1E1E",
        textSecondary: "505050",
        textMuted: "8B8B8B",
        accent: "4A6CF7",
        accentSecondary: "005A9E",
        accentTertiary: "E9730A",
        success: "388A34",
        info: "4A6CF7",
        aura1: "4A6CF7",
        aura2: "005A9E",
        aura3: "E9730A",
        ansiBlack: "1E1E1E",
        ansiRed: "CD3131",
        ansiGreen: "388A34",
        ansiYellow: "DDB100",
        ansiBlue: "0451A5",
        ansiMagenta: "BC05BC",
        ansiCyan: "0598BC",
        ansiWhite: "F3F3F3",
        ansiBrightBlack: "666666",
        ansiBrightRed: "CD3131",
        ansiBrightGreen: "14CE14",
        ansiBrightYellow: "DDB100",
        ansiBrightBlue: "0451A5",
        ansiBrightMagenta: "BC05BC",
        ansiBrightCyan: "0598BC",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "1E1E1E",
        isLight: true
    )

    // ── 3. macOS Dark ──
    static let macosDark = AppTheme(
        id: "macos_dark",
        name: "macOS Dark",
        icon: "desktopcomputer",
        base: "1C1C1E",
        surface: "2C2C2E",
        elevated: "3A3A3C",
        terminalBg: "000000",
        border: "38383A",
        borderActive: "545456",
        textPrimary: "FFFFFF",
        textSecondary: "EBEBF5",
        textMuted: "8E8E93",
        accent: "0A84FF",
        accentSecondary: "5E5CE6",
        accentTertiary: "FF9F0A",
        success: "30D158",
        info: "0A84FF",
        aura1: "0A84FF",
        aura2: "5E5CE6",
        aura3: "30D158",
        ansiBlack: "000000",
        ansiRed: "FF453A",
        ansiGreen: "32D74B",
        ansiYellow: "FFD60A",
        ansiBlue: "0A84FF",
        ansiMagenta: "BF5AF2",
        ansiCyan: "64D2FF",
        ansiWhite: "FFFFFF",
        ansiBrightBlack: "8E8E93",
        ansiBrightRed: "FF6961",
        ansiBrightGreen: "30D158",
        ansiBrightYellow: "FFD60A",
        ansiBrightBlue: "409CFF",
        ansiBrightMagenta: "DA8FFF",
        ansiBrightCyan: "70D7FF",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "FFFFFF",
        isLight: false
    )

    // ── 4. macOS Light ──
    static let macosLight = AppTheme(
        id: "macos_light",
        name: "macOS Light",
        icon: "desktopcomputer",
        base: "F2F2F7",
        surface: "FFFFFF",
        elevated: "E5E5EA",
        terminalBg: "FFFFFF",
        border: "C6C6C8",
        borderActive: "AEAEB2",
        textPrimary: "000000",
        textSecondary: "3C3C43",
        textMuted: "8E8E93",
        accent: "007AFF",
        accentSecondary: "5856D6",
        accentTertiary: "FF9500",
        success: "28CD41",
        info: "007AFF",
        aura1: "007AFF",
        aura2: "5856D6",
        aura3: "28CD41",
        ansiBlack: "000000",
        ansiRed: "FF3B30",
        ansiGreen: "34C759",
        ansiYellow: "FFCC00",
        ansiBlue: "007AFF",
        ansiMagenta: "AF52DE",
        ansiCyan: "32ADE6",
        ansiWhite: "FFFFFF",
        ansiBrightBlack: "8E8E93",
        ansiBrightRed: "FF3B30",
        ansiBrightGreen: "34C759",
        ansiBrightYellow: "FFCC00",
        ansiBrightBlue: "007AFF",
        ansiBrightMagenta: "AF52DE",
        ansiBrightCyan: "32ADE6",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "000000",
        isLight: true
    )

    // ── 5. True Black (AMOLED) ──
    static let trueBlack = AppTheme(
        id: "true_black",
        name: "True Black",
        icon: "moon.stars.fill",
        base: "000000",
        surface: "0A0A0A",
        elevated: "141414",
        terminalBg: "000000",
        border: "1C1C1C",
        borderActive: "333333",
        textPrimary: "EAEAEA",
        textSecondary: "A0A0A0",
        textMuted: "666666",
        accent: "FFFFFF",
        accentSecondary: "AAAAAA",
        accentTertiary: "555555",
        success: "34D399",
        info: "60A5FA",
        aura1: "FFFFFF",
        aura2: "AAAAAA",
        aura3: "333333",
        ansiBlack: "000000",
        ansiRed: "F87171",
        ansiGreen: "34D399",
        ansiYellow: "FBBF24",
        ansiBlue: "60A5FA",
        ansiMagenta: "A78BFA",
        ansiCyan: "22D3EE",
        ansiWhite: "EAEAEA",
        ansiBrightBlack: "666666",
        ansiBrightRed: "FCA5A5",
        ansiBrightGreen: "6EE7B7",
        ansiBrightYellow: "FDE047",
        ansiBrightBlue: "93C5FD",
        ansiBrightMagenta: "C4B5FD",
        ansiBrightCyan: "67E8F9",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "EAEAEA",
        isLight: false
    )

    // ── 6. GitHub Dark ──
    static let githubDark = AppTheme(
        id: "github_dark",
        name: "GitHub Dark",
        icon: "chevron.left.forwardslash.chevron.right",
        base: "0D1117",
        surface: "161B22",
        elevated: "21262D",
        terminalBg: "0D1117",
        border: "30363D",
        borderActive: "8B949E",
        textPrimary: "C9D1D9",
        textSecondary: "8B949E",
        textMuted: "484F58",
        accent: "58A6FF",
        accentSecondary: "1F6FEB",
        accentTertiary: "A371F7",
        success: "238636",
        info: "58A6FF",
        aura1: "58A6FF",
        aura2: "1F6FEB",
        aura3: "A371F7",
        ansiBlack: "484F58",
        ansiRed: "FF7B72",
        ansiGreen: "3FB950",
        ansiYellow: "D29922",
        ansiBlue: "58A6FF",
        ansiMagenta: "BC8CFF",
        ansiCyan: "39C5CF",
        ansiWhite: "B1BAC4",
        ansiBrightBlack: "6E7681",
        ansiBrightRed: "FFA198",
        ansiBrightGreen: "56D364",
        ansiBrightYellow: "E3B341",
        ansiBrightBlue: "79C0FF",
        ansiBrightMagenta: "D2A8FF",
        ansiBrightCyan: "56D4DD",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "C9D1D9",
        isLight: false
    )

    static let allThemes: [AppTheme] = [
        .darkModern,
        .lightModern,
        .macosDark,
        .macosLight,
        .trueBlack,
        .githubDark,
    ]
}

// MARK: - Theme Manager (ObservableObject)

class ThemeManager: ObservableObject {
    @Published var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.id, forKey: "selectedThemeId")
            // Notify terminal to reload colors
            themeChanged.send(current)
            // Update window title bar appearance
            applyWindowAppearance()
        }
    }
    
    let themeChanged = PassthroughSubject<AppTheme, Never>()
    
    init() {
        let savedId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "dark_modern"
        self.current = AppTheme.allThemes.first { $0.id == savedId } ?? .darkModern
        // Apply on launch after a short delay to ensure the window exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            applyWindowAppearance()
        }
    }
    
    func applyWindowAppearance() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        // Set window appearance to match theme (light vs dark)
        if current.isLight {
            window.appearance = NSAppearance(named: .aqua)
        } else {
            window.appearance = NSAppearance(named: .darkAqua)
        }
        
        // Make the title bar transparent and set its color to match the theme base
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = NSColor(hex: current.base)
    }
    
    // Convenience color accessors
    var base: SwiftUI.Color { SwiftUI.Color(hex: current.base) }
    var surface: SwiftUI.Color { SwiftUI.Color(hex: current.surface) }
    var elevated: SwiftUI.Color { SwiftUI.Color(hex: current.elevated) }
    var terminalBg: SwiftUI.Color { SwiftUI.Color(hex: current.terminalBg) }
    var border: SwiftUI.Color { SwiftUI.Color(hex: current.border) }
    var borderActive: SwiftUI.Color { SwiftUI.Color(hex: current.borderActive) }
    var textPrimary: SwiftUI.Color { SwiftUI.Color(hex: current.textPrimary) }
    var textSecondary: SwiftUI.Color { SwiftUI.Color(hex: current.textSecondary) }
    var textMuted: SwiftUI.Color { SwiftUI.Color(hex: current.textMuted) }
    var accent: SwiftUI.Color { SwiftUI.Color(hex: current.accent) }
    var accentSecondary: SwiftUI.Color { SwiftUI.Color(hex: current.accentSecondary) }
    var accentTertiary: SwiftUI.Color { SwiftUI.Color(hex: current.accentTertiary) }
    var success: SwiftUI.Color { SwiftUI.Color(hex: current.success) }
    var info: SwiftUI.Color { SwiftUI.Color(hex: current.info) }
}
