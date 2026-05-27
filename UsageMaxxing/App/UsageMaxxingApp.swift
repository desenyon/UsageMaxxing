import SwiftUI
import UsageMaxxingCore

@main
struct UsageMaxxingApp: App {
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @AppStorage("cachedPressureScore") private var cachedPressureScore = 0
    @AppStorage("cachedPressureLevel") private var cachedPressureLevel = UsagePressureLevel.low.rawValue
    @AppStorage("dashboardCompactMode") private var dashboardCompactMode = false

    init() {
        MenuBarController.configureAccessoryActivation()
    }

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarExtra) {
            DashboardView()
                .frame(width: 460, height: dashboardCompactMode ? 520 : 640)
        } label: {
            MenuBarStatusLabel(
                pressureScore: cachedPressureScore,
                pressureLevel: UsagePressureLevel(rawValue: cachedPressureLevel) ?? .low
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .frame(width: 520, height: 520)
        }
    }

}

private struct MenuBarStatusLabel: View {
    let pressureScore: Int
    let pressureLevel: UsagePressureLevel

    var body: some View {
        Image(systemName: "gauge.with.dots.needle.67percent")
            .symbolRenderingMode(.palette)
            .foregroundStyle(pressureColor)
            .help("UsageMaxxing · pressure \(pressureScore)% (\(pressureLevel.label))")
    }

    private var pressureColor: Color {
        switch pressureLevel {
        case .low: DashboardTheme.healthy
        case .medium: DashboardTheme.warning
        case .high: DashboardTheme.critical
        }
    }
}
