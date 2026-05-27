import SwiftUI
import UsageMaxxingCore

@MainActor
private final class ExactUsageViewModel: ObservableObject {
    @Published var snapshot: ExactUsageSnapshot?
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var pressure = UsagePressureSnapshot(score: 0, level: .low, nextReset: nil)

    var exactProviders: [ExactProviderResult] {
        let providers = snapshot?.results.filter { $0.installed && $0.status == "ok" && !$0.lines.isEmpty } ?? []
        return providers.sorted { lhs, rhs in
            peakUsage(rhs) > peakUsage(lhs)
        }
    }

    var unavailableInstalledProviders: [ExactProviderResult] {
        snapshot?.results.filter { $0.installed && $0.status != "ok" } ?? []
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        Task.detached {
            let result: Result<ExactUsageSnapshot, Error>
            do {
                let service = ExactUsageBridgeService(scriptURL: Bundle.module.url(forResource: "local_exact_usage_bridge", withExtension: "mjs")!)
                result = .success(try service.fetch())
            } catch {
                result = .failure(error)
            }

            await MainActor.run {
                self.isRefreshing = false
                switch result {
                case .success(let snapshot):
                    self.snapshot = snapshot
                    self.pressure = UsagePressureCalculator.calculate(from: snapshot)
                    UsageSyncHistory.shared.record(snapshot: snapshot)
                    UserDefaults.standard.set(self.pressure.score, forKey: "cachedPressureScore")
                    UserDefaults.standard.set(self.pressure.level.rawValue, forKey: "cachedPressureLevel")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func peakUsage(_ provider: ExactProviderResult) -> Double {
        provider.lines.compactMap { line -> Double? in
            guard let used = line.used, let limit = line.limit, limit > 0 else { return nil }
            return used / limit
        }.max() ?? 0
    }
}

struct DashboardView: View {
    @StateObject private var model = ExactUsageViewModel()
    @AppStorage("dashboardCompactMode") private var compactMode = false

    var body: some View {
        VStack(spacing: 0) {
            header
            pressureStrip

            if model.isRefreshing && model.snapshot == nil {
                loadingState
            } else if let errorMessage = model.errorMessage, model.snapshot == nil {
                errorState(errorMessage)
            } else {
                ScrollView {
                    LazyVStack(spacing: compactMode ? 6 : 8) {
                        ForEach(model.exactProviders, id: \.provider) { provider in
                            ExactProviderCardView(
                                provider: provider,
                                compactMode: compactMode,
                                isLive: model.isRefreshing
                            )
                        }

                        if !model.unavailableInstalledProviders.isEmpty {
                            unavailableSection
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(DashboardTheme.pageBackground)
        .onAppear {
            if model.snapshot == nil {
                model.refresh()
            }
        }
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

            Button {
                compactMode.toggle()
            } label: {
                Image(systemName: compactMode ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
            }
            .buttonStyle(.borderless)
            .help(compactMode ? "Standard layout" : "Compact layout")

            Button {
                model.refresh()
            } label: {
                if model.isRefreshing {
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
            Text("\(model.pressure.score)%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(pressureColor)
            Text(model.pressure.level.label)
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

    private var headerStatusLine: String {
        var parts: [String] = []
        if let snapshot = model.snapshot {
            parts.append("\(model.exactProviders.count) sources synced")
            parts.append("updated \(UsageDateFormatting.relativeString(for: snapshot.generatedAt))")
            if let nextReset = model.pressure.nextReset {
                parts.append("next reset \(UsageDateFormatting.relativeString(for: nextReset))")
            }
            parts.append("pressure \(model.pressure.level.label)")
        } else {
            parts.append("Exact local app usage only")
        }
        return parts.joined(separator: " · ")
    }

    private var pressureColor: Color {
        switch model.pressure.level {
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
                model.refresh()
            }
            Spacer()
        }
    }

    private var unavailableSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Installed but unavailable")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(model.unavailableInstalledProviders, id: \.provider) { provider in
                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(DashboardTheme.railColor(for: provider.provider).opacity(0.5))
                        .frame(width: 3, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DashboardTheme.displayName(for: provider.provider))
                            .font(.system(size: 11, weight: .bold))
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
