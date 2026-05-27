import SwiftUI

struct SettingsView: View {
    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes = 15
    @AppStorage("privacyMode") private var privacyMode = true
    @AppStorage("dashboardCompactMode") private var dashboardCompactMode = false
    @State private var showingPrivacy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.title2.weight(.semibold))
                    Text("Exact local app data only")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.18), in: Capsule())
                }
                Spacer()
                Button {
                    showingPrivacy = true
                } label: {
                    Label("Privacy", systemImage: "hand.raised")
                }
            }

            section("Data Sources") {
                Text("UsageMaxxing reads installed OpenUsage-compatible local plugins from Application Support and displays only exact lines returned by those plugins. It does not show mock, manual, hardcoded, or estimated provider data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("~/Library/Application Support/com.sunstory.openusage/plugins")
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
            }

            section("Display") {
                Toggle("Compact dashboard", isOn: $dashboardCompactMode)
                Text("Shows two-line provider summaries and tighter cards in the menu bar window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            section("Refresh") {
                Picker("Refresh interval", selection: $refreshIntervalMinutes) {
                    Text("5 minutes").tag(5)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                }
                Toggle("Privacy mode", isOn: $privacyMode)
            }

            section("Installed App Rule") {
                Text("A provider appears only when its macOS app is installed and its exact usage plugin returns live quota data. Installed apps with expired auth or unavailable local state appear separately as unavailable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(22)
        .background(DashboardTheme.pageBackground)
        .sheet(isPresented: $showingPrivacy) {
            PrivacyView()
                .frame(width: 460, height: 420)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .padding(12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
    }
}
