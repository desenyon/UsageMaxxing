import Foundation

public final class UsageSyncHistory: @unchecked Sendable {
    public static let shared = UsageSyncHistory()

    private let defaults: UserDefaults
    private let lock = NSLock()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func previousUsed(provider: String, label: String) -> Double? {
        lock.lock()
        defer { lock.unlock() }
        let key = storageKey(provider: provider, label: label)
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.double(forKey: key)
    }

    public func record(snapshot: ExactUsageSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        for result in snapshot.results where result.installed && result.status == "ok" {
            for line in result.lines {
                guard let used = line.used else { continue }
                let label = line.label ?? line.type
                defaults.set(used, forKey: storageKey(provider: result.provider, label: label))
            }
        }
        defaults.set(snapshot.generatedAt.timeIntervalSince1970, forKey: "usageMaxxing.lastSync")
    }

    private func storageKey(provider: String, label: String) -> String {
        "usageMaxxing.history.\(provider).\(label)"
    }
}
