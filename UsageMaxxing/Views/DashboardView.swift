import SwiftUI
import UsageMaxxingCore

struct DashboardView: View {
    @EnvironmentObject private var dashboard: UsageDashboardModel
    @AppStorage("dashboardCompactMode") private var compactMode = false
    @AppStorage("showPressureStrip") private var showPressureStrip = true

    var body: some View {
        VStack(spacing: 0) {
            header
            if showPressureStrip {
                pressureStrip
            }
            summaryBar

            if dashboard.isRefreshing && dashboard.snapshot == nil {
                loadingState
            } else if let errorMessage = dashboard.errorMessage, dashboard.snapshot == nil {
                errorState(errorMessage)
            } else if dashboard.exactProviders.isEmpty {
                emptyExactState
            } else {
                ScrollView {
                    LazyVStack(spacing: compactMode ? 6 : 8) {
                        ForEach(dashboard.exactProviders, id: \.provider) { provider in
                            ExactProviderCardView(
                                provider: provider,
                                compactMode: compactMode,
                                isLive: dashboard.isRefreshing
                            )
                        }

                        if !dashboard.unavailableInstalledProviders.isEmpty {
                            unavailableSection
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(DashboardTheme.pageBackground)
        .onAppear { dashboard.onAppear() }
        .onDisappear { dashboard.onDisappear() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(pressureColor)

            VStack(alignment: .leading, spacing: 1) {
                Text("UsageMaxxing")
                    .font(.system(size: 15, weight: .bold))
                Text(headerStatusLine)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text("Exact only")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(DashboardTheme.healthy.opacity(0.14), in: Capsule())
                .foregroundStyle(DashboardTheme.healthy)

            Button {
                compactMode.toggle()
            } label: {
                Image(systemName: compactMode ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
            }
            .buttonStyle(.borderless)
            .help(compactMode ? "Standard layout" : "Compact layout")

            Button {
                dashboard.refresh()
            } label: {
                if dashboard.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderless)
            .help("Refresh exact local usage")

            Button {
                MenuBarController.openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DashboardTheme.headerBackground)
    }

    private var pressureStrip: some View {
        HStack(spacing: 8) {
            Text("AI Capacity Pressure")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(dashboard.pressure.score)%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(pressureColor)
            Text(dashboard.pressure.level.label)
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(pressureColor.opacity(0.14), in: Capsule())
                .foregroundStyle(pressureColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DashboardTheme.cardBackground.opacity(0.65))
    }

    private var summaryBar: some View {
        HStack(spacing: 8) {
            summaryPill(
                title: "Live",
                value: "\(dashboard.exactProviders.count)",
                color: DashboardTheme.healthy
            )
            summaryPill(
                title: "Unavailable",
                value: "\(dashboard.unavailableInstalledProviders.count)",
                color: dashboard.unavailableInstalledProviders.isEmpty ? DashboardTheme.unknown : DashboardTheme.warning
            )
            summaryPill(
                title: "Plugins",
                value: "\(dashboard.diagnostics.installedPluginCount)",
                color: dashboard.diagnostics.pluginDirectoryExists ? DashboardTheme.unknown : DashboardTheme.critical
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(DashboardTheme.pageBackground)
    }

    private func summaryPill(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 2)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(DashboardTheme.cardBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(DashboardTheme.cardBorder)
        )
    }

    private var headerStatusLine: String {
        var parts: [String] = []
        if let snapshot = dashboard.snapshot {
            parts.append("\(dashboard.exactProviders.count) sources synced")
            parts.append("updated \(UsageDateFormatting.relativeString(for: snapshot.generatedAt))")
            if let nextReset = dashboard.pressure.nextReset {
                parts.append("next reset \(UsageDateFormatting.relativeString(for: nextReset))")
            }
            parts.append("pressure \(dashboard.pressure.level.label)")
        } else {
            parts.append("Exact local app usage only")
        }
        return parts.joined(separator: " · ")
    }

    private var pressureColor: Color {
        switch dashboard.pressure.level {
        case .low: DashboardTheme.healthy
        case .medium: DashboardTheme.warning
        case .high: DashboardTheme.critical
        }
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            Spacer()
            ProgressView()
            Text("Reading installed app usage")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(DashboardTheme.warning)
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Button("Retry") {
                dashboard.refresh()
            }
            Spacer()
        }
    }

    private var emptyExactState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "sensor.tag.radiowaves.forward")
                .font(.system(size: 25))
                .foregroundStyle(DashboardTheme.warning)
            Text("No exact usage sources returned data")
                .font(.system(size: 13, weight: .bold))
            Text("Install provider apps, keep local auth valid, and make sure OpenUsage-compatible plugins are present.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
            Button("Refresh") {
                dashboard.refresh()
            }
            Spacer()
        }
    }

    private var unavailableSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Installed but unavailable")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(dashboard.unavailableInstalledProviders, id: \.provider) { provider in
                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(DashboardTheme.railColor(for: provider.provider).opacity(0.5))
                        .frame(width: 3, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DashboardTheme.displayName(for: provider.provider))
                            .font(.system(size: 11, weight: .bold))
                        Text("Action needed")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(DashboardTheme.warning)
                        Text(provider.error ?? provider.status)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(DashboardTheme.cardBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}
