import SwiftUI
import Combine

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

    // ── Dashbin Classic: Deep navy from the app icon (#1E2A78 accent) ──
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
        accent: "4A6CF7",       // Dashbin icon blue
        accentSecondary: "7B93FF",
        accentTertiary: "F0C050",
        success: "5AE87B",
        info: "4A6CF7",
        aura1: "4A6CF7",        // Blue glow
        aura2: "7B93FF",        // Lighter blue
        aura3: "F0C050",        // Warm amber
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

    // ── Obsidian: The deep charcoal / lime theme we just built ──
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

    // ── Arctic: Clean light theme with high contrast ──
    static let arctic = AppTheme(
        id: "arctic",
        name: "Arctic",
        icon: "sun.max.fill",
        base: "F5F5F7",
        surface: "FFFFFF",
        elevated: "EAEAEC",
        terminalBg: "FAFAFA",
        border: "D1D1D6",
        borderActive: "B0B0B8",
        textPrimary: "1A1A1A",
        textSecondary: "505058",
        textMuted: "8E8E93",
        accent: "0066FF",
        accentSecondary: "5856D6",
        accentTertiary: "FF9500",
        success: "28A745",
        info: "0066FF",
        aura1: "0066FF",
        aura2: "5856D6",
        aura3: "FF9500",
        ansiBlack: "1A1A1A",
        ansiRed: "D32F2F",
        ansiGreen: "2E7D32",
        ansiYellow: "F57F17",
        ansiBlue: "1565C0",
        ansiMagenta: "7B1FA2",
        ansiCyan: "00838F",
        ansiWhite: "F5F5F7",
        ansiBrightBlack: "6D6D72",
        ansiBrightRed: "E53935",
        ansiBrightGreen: "43A047",
        ansiBrightYellow: "FFA000",
        ansiBrightBlue: "1E88E5",
        ansiBrightMagenta: "8E24AA",
        ansiBrightCyan: "0097A7",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "1A1A1A",
        isLight: true
    )

    // ── Ember: Warm, fiery dark theme ──
    static let ember = AppTheme(
        id: "ember",
        name: "Ember",
        icon: "flame.fill",
        base: "120A08",
        surface: "1C1210",
        elevated: "261A16",
        terminalBg: "140C0A",
        border: "3A2820",
        borderActive: "4E362C",
        textPrimary: "F0E4DC",
        textSecondary: "B8A498",
        textMuted: "7A6458",
        accent: "FF6A3D",
        accentSecondary: "FFB347",
        accentTertiary: "FF4080",
        success: "4ADE80",
        info: "FF6A3D",
        aura1: "FF6A3D",
        aura2: "FF4080",
        aura3: "FFB347",
        ansiBlack: "1E1410",
        ansiRed: "FF5C5C",
        ansiGreen: "4ADE80",
        ansiYellow: "FFB347",
        ansiBlue: "60A5FA",
        ansiMagenta: "FF4080",
        ansiCyan: "22D3EE",
        ansiWhite: "F0E4DC",
        ansiBrightBlack: "5A4A42",
        ansiBrightRed: "FCA5A5",
        ansiBrightGreen: "86EFAC",
        ansiBrightYellow: "FDE68A",
        ansiBrightBlue: "93C5FD",
        ansiBrightMagenta: "F472B6",
        ansiBrightCyan: "67E8F9",
        ansiBrightWhite: "FFFFFF",
        terminalFg: "F0E4DC",
        isLight: false
    )

    // ── Synthwave: Neon purple / pink retro theme ──
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
        .obsidian,
        .arctic,
        .ember,
        .synthwave
    ]
}

// MARK: - Theme Manager (ObservableObject)

class ThemeManager: ObservableObject {
    @Published var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.id, forKey: "selectedThemeId")
            // Notify terminal to reload colors
            themeChanged.send(current)
        }
    }
    
    let themeChanged = PassthroughSubject<AppTheme, Never>()
    
    init() {
        let savedId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "dashbin_classic"
        self.current = AppTheme.allThemes.first { $0.id == savedId } ?? .dashbinClassic
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
