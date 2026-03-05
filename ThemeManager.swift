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

    // ── 1. Dashbin Classic: Deep navy from the app icon ──
    static let dashbinClassic = AppTheme(
        id: "dashbin_classic",
        name: "Dashbin Classic",
        icon: "chevron.forward.2",
        base: "0A0C1A",
        surface: "111530",
        elevated: "1A1F42",
        terminalBg: "0C0E1E",
        border: "252B55",
        borderActive: "354070",
        textPrimary: "E8EAFF",
        textSecondary: "A0A4CC",
        textMuted: "5A5F8A",
        accent: "4A6CF7",
        accentSecondary: "7B93FF",
        accentTertiary: "F0C050",
        success: "5AE87B",
        info: "4A6CF7",
        aura1: "4A6CF7",
        aura2: "7B93FF",
        aura3: "F0C050",
        ansiBlack: "181C3A",
        ansiRed: "FF6B6B",
        ansiGreen: "5AE87B",
        ansiYellow: "F0C050",
        ansiBlue: "4A6CF7",
        ansiMagenta: "C084FC",
        ansiCyan: "22D3EE",
        ansiWhite: "E8EAFF",
        ansiBrightBlack: "3A4070",
        ansiBrightRed: "FCA5A5",
        ansiBrightGreen: "86EFAC",
        ansiBrightYellow: "FDE68A",
        ansiBrightBlue: "7B93FF",
        ansiBrightMagenta: "D8B4FE",
        ansiBrightCyan: "67E8F9",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "E8EAFF",
        isLight: false
    )

    // ── 2. Dark Modern: VS Code Default Dark Modern ──
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
        accent: "0078D4",
        accentSecondary: "4FC1FF",
        accentTertiary: "DCDCAA",
        success: "6A9955",
        info: "4FC1FF",
        aura1: "0078D4",
        aura2: "4FC1FF",
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

    // ── 3. Light Modern: VS Code Default Light Modern ──
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
        accent: "0078D4",
        accentSecondary: "005A9E",
        accentTertiary: "E9730A",
        success: "388A34",
        info: "0078D4",
        aura1: "0078D4",
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

    // ── 4. Obsidian: Deep charcoal / lime ──
    static let obsidian = AppTheme(
        id: "obsidian",
        name: "Obsidian",
        icon: "moon.fill",
        base: "0A0A0A",
        surface: "141414",
        elevated: "1A1A1A",
        terminalBg: "0C0C0E",
        border: "2A2A2A",
        borderActive: "3A3A3A",
        textPrimary: "E8E8E8",
        textSecondary: "A0A0A0",
        textMuted: "6B6B6B",
        accent: "B5FF3D",
        accentSecondary: "3B82F6",
        accentTertiary: "FBBF24",
        success: "B5FF3D",
        info: "3B82F6",
        aura1: "B5FF3D",
        aura2: "3B82F6",
        aura3: "FBBF24",
        ansiBlack: "1A1A1E",
        ansiRed: "FF6B6B",
        ansiGreen: "B5FF3D",
        ansiYellow: "FBBF24",
        ansiBlue: "3B82F6",
        ansiMagenta: "C084FC",
        ansiCyan: "22D3EE",
        ansiWhite: "E8E8E8",
        ansiBrightBlack: "4A4A52",
        ansiBrightRed: "FCA5A5",
        ansiBrightGreen: "D4FF7A",
        ansiBrightYellow: "FDE68A",
        ansiBrightBlue: "60A5FA",
        ansiBrightMagenta: "D8B4FE",
        ansiBrightCyan: "67E8F9",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "E8E8E8",
        isLight: false
    )

    // ── 5. Nord: Cool arctic frost ──
    static let nord = AppTheme(
        id: "nord",
        name: "Nord",
        icon: "snowflake",
        base: "2E3440",
        surface: "3B4252",
        elevated: "434C5E",
        terminalBg: "2E3440",
        border: "4C566A",
        borderActive: "5E81AC",
        textPrimary: "ECEFF4",
        textSecondary: "D8DEE9",
        textMuted: "7B88A1",
        accent: "88C0D0",
        accentSecondary: "5E81AC",
        accentTertiary: "EBCB8B",
        success: "A3BE8C",
        info: "88C0D0",
        aura1: "88C0D0",
        aura2: "5E81AC",
        aura3: "EBCB8B",
        ansiBlack: "3B4252",
        ansiRed: "BF616A",
        ansiGreen: "A3BE8C",
        ansiYellow: "EBCB8B",
        ansiBlue: "81A1C1",
        ansiMagenta: "B48EAD",
        ansiCyan: "88C0D0",
        ansiWhite: "E5E9F0",
        ansiBrightBlack: "4C566A",
        ansiBrightRed: "BF616A",
        ansiBrightGreen: "A3BE8C",
        ansiBrightYellow: "EBCB8B",
        ansiBrightBlue: "81A1C1",
        ansiBrightMagenta: "B48EAD",
        ansiBrightCyan: "8FBCBB",
        ansiBrightWhite: "ECEFF4",
        terminalFg: "ECEFF4",
        isLight: false
    )

    // ── 6. Catppuccin Mocha: Pastel dark ──
    static let catppuccin = AppTheme(
        id: "catppuccin",
        name: "Catppuccin Mocha",
        icon: "cup.and.saucer.fill",
        base: "1E1E2E",
        surface: "2A2A3C",
        elevated: "313244",
        terminalBg: "1E1E2E",
        border: "45475A",
        borderActive: "585B70",
        textPrimary: "CDD6F4",
        textSecondary: "BAC2DE",
        textMuted: "6C7086",
        accent: "CBA6F7",
        accentSecondary: "89B4FA",
        accentTertiary: "F9E2AF",
        success: "A6E3A1",
        info: "89B4FA",
        aura1: "CBA6F7",
        aura2: "89B4FA",
        aura3: "F9E2AF",
        ansiBlack: "45475A",
        ansiRed: "F38BA8",
        ansiGreen: "A6E3A1",
        ansiYellow: "F9E2AF",
        ansiBlue: "89B4FA",
        ansiMagenta: "CBA6F7",
        ansiCyan: "94E2D5",
        ansiWhite: "CDD6F4",
        ansiBrightBlack: "585B70",
        ansiBrightRed: "F38BA8",
        ansiBrightGreen: "A6E3A1",
        ansiBrightYellow: "F9E2AF",
        ansiBrightBlue: "89B4FA",
        ansiBrightMagenta: "CBA6F7",
        ansiBrightCyan: "94E2D5",
        ansiBrightWhite: "CDD6F4",
        terminalFg: "CDD6F4",
        isLight: false
    )

    // ── 7. Monokai Pro: Warm muted dark with vivid syntax ──
    static let monokaiPro = AppTheme(
        id: "monokai_pro",
        name: "Monokai Pro",
        icon: "paintbrush.fill",
        base: "2D2A2E",
        surface: "403E41",
        elevated: "4A474D",
        terminalBg: "2D2A2E",
        border: "524F56",
        borderActive: "727072",
        textPrimary: "FCFCFA",
        textSecondary: "C1C0C0",
        textMuted: "727072",
        accent: "FFD866",
        accentSecondary: "78DCE8",
        accentTertiary: "FF6188",
        success: "A9DC76",
        info: "78DCE8",
        aura1: "FFD866",
        aura2: "FF6188",
        aura3: "78DCE8",
        ansiBlack: "403E41",
        ansiRed: "FF6188",
        ansiGreen: "A9DC76",
        ansiYellow: "FFD866",
        ansiBlue: "FC9867",
        ansiMagenta: "AB9DF2",
        ansiCyan: "78DCE8",
        ansiWhite: "FCFCFA",
        ansiBrightBlack: "727072",
        ansiBrightRed: "FF6188",
        ansiBrightGreen: "A9DC76",
        ansiBrightYellow: "FFD866",
        ansiBrightBlue: "FC9867",
        ansiBrightMagenta: "AB9DF2",
        ansiBrightCyan: "78DCE8",
        ansiBrightWhite: "FCFCFA",
        terminalFg: "FCFCFA",
        isLight: false
    )

    // ── 8. Solarized Dark: Classic warm dark ──
    static let solarizedDark = AppTheme(
        id: "solarized_dark",
        name: "Solarized Dark",
        icon: "sun.haze.fill",
        base: "002B36",
        surface: "073642",
        elevated: "0A4050",
        terminalBg: "002B36",
        border: "1A5060",
        borderActive: "268BD2",
        textPrimary: "FDF6E3",
        textSecondary: "93A1A1",
        textMuted: "586E75",
        accent: "268BD2",
        accentSecondary: "2AA198",
        accentTertiary: "B58900",
        success: "859900",
        info: "268BD2",
        aura1: "268BD2",
        aura2: "2AA198",
        aura3: "B58900",
        ansiBlack: "073642",
        ansiRed: "DC322F",
        ansiGreen: "859900",
        ansiYellow: "B58900",
        ansiBlue: "268BD2",
        ansiMagenta: "D33682",
        ansiCyan: "2AA198",
        ansiWhite: "EEE8D5",
        ansiBrightBlack: "586E75",
        ansiBrightRed: "CB4B16",
        ansiBrightGreen: "93A1A1",
        ansiBrightYellow: "839496",
        ansiBrightBlue: "657B83",
        ansiBrightMagenta: "6C71C4",
        ansiBrightCyan: "FDF6E3",
        ansiBrightWhite: "FDF6E3",
        terminalFg: "FDF6E3",
        isLight: false
    )

    // ── 9. Rosé Pine: Muted rose / dawn ──
    static let rosePine = AppTheme(
        id: "rose_pine",
        name: "Rosé Pine",
        icon: "sparkles",
        base: "191724",
        surface: "1F1D2E",
        elevated: "26233A",
        terminalBg: "191724",
        border: "312E44",
        borderActive: "44405A",
        textPrimary: "E0DEF4",
        textSecondary: "908CAA",
        textMuted: "6E6A86",
        accent: "EBBCBA",
        accentSecondary: "C4A7E7",
        accentTertiary: "F6C177",
        success: "9CCFD8",
        info: "C4A7E7",
        aura1: "EBBCBA",
        aura2: "C4A7E7",
        aura3: "F6C177",
        ansiBlack: "26233A",
        ansiRed: "EB6F92",
        ansiGreen: "9CCFD8",
        ansiYellow: "F6C177",
        ansiBlue: "31748F",
        ansiMagenta: "C4A7E7",
        ansiCyan: "9CCFD8",
        ansiWhite: "E0DEF4",
        ansiBrightBlack: "6E6A86",
        ansiBrightRed: "EB6F92",
        ansiBrightGreen: "9CCFD8",
        ansiBrightYellow: "F6C177",
        ansiBrightBlue: "31748F",
        ansiBrightMagenta: "C4A7E7",
        ansiBrightCyan: "EBBCBA",
        ansiBrightWhite: "E0DEF4",
        terminalFg: "E0DEF4",
        isLight: false
    )

    // ── 10. Synthwave: Neon retro ──
    static let synthwave = AppTheme(
        id: "synthwave",
        name: "Synthwave",
        icon: "waveform",
        base: "0E0618",
        surface: "160E24",
        elevated: "1E1430",
        terminalBg: "100818",
        border: "302450",
        borderActive: "443268",
        textPrimary: "F0E6FF",
        textSecondary: "B8A0D8",
        textMuted: "6B5A8A",
        accent: "E040FB",
        accentSecondary: "00E5FF",
        accentTertiary: "FFD740",
        success: "69F0AE",
        info: "00E5FF",
        aura1: "E040FB",
        aura2: "00E5FF",
        aura3: "FFD740",
        ansiBlack: "1A1028",
        ansiRed: "FF5370",
        ansiGreen: "69F0AE",
        ansiYellow: "FFD740",
        ansiBlue: "40C4FF",
        ansiMagenta: "E040FB",
        ansiCyan: "00E5FF",
        ansiWhite: "F0E6FF",
        ansiBrightBlack: "4A3870",
        ansiBrightRed: "FF8A80",
        ansiBrightGreen: "B9F6CA",
        ansiBrightYellow: "FFE57F",
        ansiBrightBlue: "80D8FF",
        ansiBrightMagenta: "EA80FC",
        ansiBrightCyan: "84FFFF",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "F0E6FF",
        isLight: false
    )

    static let allThemes: [AppTheme] = [
        .dashbinClassic,
        .darkModern,
        .lightModern,
        .obsidian,
        .nord,
        .catppuccin,
        .monokaiPro,
        .solarizedDark,
        .rosePine,
        .synthwave,
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
        let savedId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "dashbin_classic"
        self.current = AppTheme.allThemes.first { $0.id == savedId } ?? .dashbinClassic
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
