import AppKit
import ServiceManagement
import SwiftUI
import UsageMaxxingCore

struct SettingsView: View {
    @EnvironmentObject private var dashboard: UsageDashboardModel

    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes = 15
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("privacyMode") private var privacyMode = true
    @AppStorage("dashboardCompactMode") private var dashboardCompactMode = false
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @AppStorage("showPressureStrip") private var showPressureStrip = true
    @AppStorage("showPredictiveInsights") private var showPredictiveInsights = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("sortByUrgency") private var sortByUrgency = true

    @State private var showingPrivacy = false
    @State private var launchAtLoginError: String?
    @State private var copiedPath = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                generalSection
                syncSection
                displaySection
                dataSourcesSection
                systemStatusSection
                aboutSection
            }
            .padding(18)
        }
        .background(DashboardTheme.pageBackground)
        .onAppear {
            dashboard.reloadDiagnostics()
            syncLaunchAtLoginState()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyView()
                .frame(width: 460, height: 420)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("UsageMaxxing")
                    .font(.system(size: 20, weight: .bold))
                Text("Exact local usage · v\(AppInfo.fullVersion)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 9))
                    Text("OpenUsage plugin bridge")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                showingPrivacy = true
            } label: {
                Label("Privacy", systemImage: "hand.raised")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderless)
        }
        .padding(.bottom, 4)
    }

    private var generalSection: some View {
        SettingsSection(title: "General", subtitle: "Menu bar presence and startup") {
            SettingsToggleRow(
                title: "Show menu bar icon",
                help: "Hide to run headless; reopen from Applications.",
                isOn: $showMenuBarExtra
            )
            Divider().opacity(0.25)
            SettingsToggleRow(
                title: "Launch at login",
                help: "Start UsageMaxxing when you sign in to macOS.",
                isOn: $launchAtLogin
            )
            .onChange(of: launchAtLogin) { _, enabled in
                updateLaunchAtLogin(enabled)
            }
            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DashboardTheme.warning)
            }
        }
    }

    private var syncSection: some View {
        SettingsSection(title: "Sync", subtitle: "Automatic refresh of installed plugin data") {
            SettingsToggleRow(
                title: "Auto-refresh",
                help: "Poll local plugins on an interval.",
                isOn: $autoRefreshEnabled
            )
            .onChange(of: autoRefreshEnabled) { _, _ in
                applyRefreshPreferences()
            }

            Picker("Refresh interval", selection: $refreshIntervalMinutes) {
                Text("5 minutes").tag(5)
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("1 hour").tag(60)
            }
            .font(.system(size: 12, weight: .medium))
            .onChange(of: refreshIntervalMinutes) { _, _ in
                applyRefreshPreferences()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last sync")
                        .font(.system(size: 11, weight: .semibold))
                    if let lastSync = dashboard.lastSyncDate {
                        Text(UsageDateFormatting.shortDateTimeString(for: lastSync))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not synced yet")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    dashboard.refresh()
                } label: {
                    if dashboard.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Refresh now", systemImage: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(dashboard.isRefreshing)
            }
            .padding(.top, 4)
        }
    }

    private var displaySection: some View {
        SettingsSection(title: "Display", subtitle: "Dashboard density and telemetry overlays") {
            SettingsToggleRow(
                title: "Compact dashboard",
                help: "Two-line provider summaries in the menu bar window.",
                isOn: $dashboardCompactMode
            )
            Divider().opacity(0.25)
            SettingsToggleRow(
                title: "AI Capacity Pressure strip",
                help: "Global pressure score below the header.",
                isOn: $showPressureStrip
            )
            SettingsToggleRow(
                title: "Predictive insights",
                help: "Depletion estimates, velocity, and burn notes on metrics.",
                isOn: $showPredictiveInsights
            )
            SettingsToggleRow(
                title: "Sort cards by urgency",
                help: "Highest utilization providers appear first.",
                isOn: $sortByUrgency
            )
            Divider().opacity(0.25)
            SettingsToggleRow(
                title: "Privacy mode",
                help: "Mask usage percentages and values in the dashboard.",
                isOn: $privacyMode
            )
        }
    }

    private var dataSourcesSection: some View {
        SettingsSection(title: "Data sources", subtitle: "OpenUsage-compatible local plugins") {
            Text("UsageMaxxing reads exact quota lines from installed plugins. No cloud backend, mock data, or manual entries.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppInfo.pluginDirectory)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DashboardTheme.trackBackground, in: RoundedRectangle(cornerRadius: 6))

            HStack(spacing: 10) {
                Button("Open in Finder") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: AppInfo.pluginDirectory, isDirectory: true))
                }
                .controlSize(.small)

                Button(copiedPath ? "Copied" : "Copy path") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(AppInfo.pluginDirectory, forType: .string)
                    copiedPath = true
                }
                .controlSize(.small)

                SettingsLinkButton(title: "View releases", icon: "tag") {
                    NSWorkspace.shared.open(AppInfo.releasesURL)
                }
            }
            .font(.system(size: 11, weight: .semibold))
        }
    }

    private var systemStatusSection: some View {
        SettingsSection(title: "System status", subtitle: "Requirements for installed-app usage") {
            SettingsStatusRow(
                title: "Node.js",
                value: dashboard.diagnostics.nodePath ?? "Not found — install Node 18+",
                isHealthy: dashboard.diagnostics.nodePath != nil
            )
            SettingsStatusRow(
                title: "Plugin directory",
                value: dashboard.diagnostics.pluginDirectoryExists
                    ? "Found · \(dashboard.diagnostics.installedPluginCount) entries"
                    : "Missing — install OpenUsage plugins",
                isHealthy: dashboard.diagnostics.pluginDirectoryExists
            )
            SettingsStatusRow(
                title: "Bridge script",
                value: dashboard.diagnostics.bridgeScriptAvailable
                    ? "Bundled in app"
                    : "Missing from app bundle",
                isHealthy: dashboard.diagnostics.bridgeScriptAvailable
            )
            SettingsStatusRow(
                title: "Ready to sync",
                value: dashboard.diagnostics.isReadyForSync ? "All requirements met" : "Fix issues above",
                isHealthy: dashboard.diagnostics.isReadyForSync
            )

            Button("Re-check requirements") {
                dashboard.reloadDiagnostics()
            }
            .controlSize(.small)
            .padding(.top, 4)
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: "About") {
            HStack {
                Text("Version")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text(AppInfo.fullVersion)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

            SettingsLinkButton(title: "GitHub repository", icon: "link") {
                NSWorkspace.shared.open(AppInfo.repositoryURL)
            }

            SettingsLinkButton(title: "Changelog", icon: "doc.text") {
                NSWorkspace.shared.open(AppInfo.repositoryURL.appendingPathComponent("blob/main/CHANGELOG.md"))
            }

            Text("Provider apps must be installed. Plugins return live usage only when local auth is valid.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private func applyRefreshPreferences() {
        dashboard.applyRefreshPreferences(
            intervalMinutes: refreshIntervalMinutes,
            autoRefresh: autoRefreshEnabled
        )
    }

    private func syncLaunchAtLoginState() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = false
            launchAtLoginError = error.localizedDescription
        }
    }
}
