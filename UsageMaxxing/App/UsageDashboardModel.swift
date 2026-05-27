import Foundation
import SwiftUI
import UsageMaxxingCore

@MainActor
final class UsageDashboardModel: ObservableObject {
    @Published var snapshot: ExactUsageSnapshot?
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var pressure = UsagePressureSnapshot(score: 0, level: .low, nextReset: nil)
    @Published var diagnostics = EnvironmentDiagnosticReport(
        nodePath: nil,
        pluginDirectoryExists: false,
        pluginDirectoryPath: AppInfo.pluginDirectory,
        installedPluginCount: 0,
        bridgeScriptAvailable: false
    )

    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes = 15
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true

    private var refreshTimer: Timer?

    var exactProviders: [ExactProviderResult] {
        let providers = snapshot?.results.filter { $0.installed && $0.status == "ok" && !$0.lines.isEmpty } ?? []
        let sortByUrgency = UserDefaults.standard.object(forKey: "sortByUrgency") as? Bool ?? true
        if sortByUrgency {
            return providers.sorted { peakUsage($0) > peakUsage($1) }
        }
        return providers.sorted { $0.provider.localizedCaseInsensitiveCompare($1.provider) == .orderedAscending }
    }

    var unavailableInstalledProviders: [ExactProviderResult] {
        snapshot?.results.filter { $0.installed && $0.status != "ok" } ?? []
    }

    var lastSyncDate: Date? {
        if let snapshot { return snapshot.generatedAt }
        let interval = UserDefaults.standard.double(forKey: "usageMaxxing.lastSync")
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    func onAppear() {
        reloadDiagnostics()
        configureAutoRefresh()
        if snapshot == nil {
            refresh()
        }
    }

    func onDisappear() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func reloadDiagnostics() {
        let bridgePath = Bundle.module.url(forResource: "local_exact_usage_bridge", withExtension: "mjs")?.path
        diagnostics = EnvironmentDiagnostics.evaluate(bridgeScriptPath: bridgePath)
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        reloadDiagnostics()

        Task.detached { [bridgeURL = Bundle.module.url(forResource: "local_exact_usage_bridge", withExtension: "mjs")] in
            let result: Result<ExactUsageSnapshot, Error>
            do {
                guard let bridgeURL else {
                    throw ExactUsageBridgeError.scriptMissing
                }
                let service = ExactUsageBridgeService(scriptURL: bridgeURL)
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
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func configureAutoRefresh() {
        refreshTimer?.invalidate()
        guard autoRefreshEnabled else {
            refreshTimer = nil
            return
        }

        let interval = max(60.0, Double(refreshIntervalMinutes) * 60.0)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func applyRefreshPreferences(intervalMinutes: Int, autoRefresh: Bool) {
        refreshIntervalMinutes = intervalMinutes
        autoRefreshEnabled = autoRefresh
        configureAutoRefresh()
    }

    private func peakUsage(_ provider: ExactProviderResult) -> Double {
        provider.lines.compactMap { line -> Double? in
            guard let used = line.used, let limit = line.limit, limit > 0 else { return nil }
            return used / limit
        }.max() ?? 0
    }
}
