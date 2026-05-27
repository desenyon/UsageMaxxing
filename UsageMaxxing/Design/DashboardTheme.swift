import SwiftUI
import UsageMaxxingCore

enum DashboardTheme {
    static let pageBackground = Color(red: 0.035, green: 0.035, blue: 0.035)
    static let cardBackground = Color(red: 0.078, green: 0.078, blue: 0.078)
    static let trackBackground = Color(red: 0.137, green: 0.137, blue: 0.137)
    static let headerBackground = Color(red: 0.05, green: 0.05, blue: 0.052)
    static let cardBorder = Color.white.opacity(0.09)

    static let critical = Color(red: 1.0, green: 0.31, blue: 0.31)
    static let warning = Color(red: 0.95, green: 0.72, blue: 0.24)
    static let healthy = Color(red: 0.28, green: 0.82, blue: 0.54)
    static let unknown = Color(red: 0.55, green: 0.57, blue: 0.6)

    static func color(for intensity: UsageIntensity) -> Color {
        switch intensity {
        case .critical: critical
        case .warning: warning
        case .healthy: healthy
        case .unknown: unknown
        }
    }

    static func railColor(for provider: String) -> Color {
        switch provider {
        case "codex": Color(red: 0.95, green: 0.28, blue: 0.28)
        case "cursor": Color(red: 0.28, green: 0.82, blue: 0.54)
        case "claude": Color(red: 0.95, green: 0.55, blue: 0.22)
        case "gemini": Color(red: 0.35, green: 0.62, blue: 0.98)
        case "antigravity": Color(red: 0.68, green: 0.45, blue: 0.98)
        case "perplexity": Color(red: 0.32, green: 0.78, blue: 0.86)
        default: Color(red: 0.5, green: 0.52, blue: 0.56)
        }
    }

    static func displayName(for provider: String) -> String {
        switch provider {
        case "claude": "Claude"
        case "codex": "Codex"
        case "cursor": "Cursor"
        case "gemini": "Gemini"
        case "antigravity": "Antigravity"
        case "perplexity": "Perplexity"
        default: provider.capitalized
        }
    }
}
