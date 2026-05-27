import Foundation

public enum UsagePressureLevel: String, Sendable, Equatable {
    case low
    case medium
    case high

    public var label: String {
        switch self {
        case .low: "low"
        case .medium: "elevated"
        case .high: "high"
        }
    }
}

public struct UsagePressureSnapshot: Equatable, Sendable {
    public let score: Int
    public let level: UsagePressureLevel
    public let nextReset: Date?

    public init(score: Int, level: UsagePressureLevel, nextReset: Date?) {
        self.score = score
        self.level = level
        self.nextReset = nextReset
    }
}

public enum UsagePressureCalculator {
    public static func calculate(from snapshot: ExactUsageSnapshot, now: Date = Date()) -> UsagePressureSnapshot {
        let lines = snapshot.results
            .filter { $0.installed && $0.status == "ok" }
            .flatMap(\.lines)
            .filter { $0.type == "progress" }

        let ratios = lines.compactMap { line -> Double? in
            guard let used = line.used, let limit = line.limit, limit > 0 else { return nil }
            return min(max(used / limit, 0), 1)
        }

        guard !ratios.isEmpty else {
            return UsagePressureSnapshot(score: 0, level: .low, nextReset: nearestReset(in: lines, now: now))
        }

        let average = ratios.reduce(0, +) / Double(ratios.count)
        let peak = ratios.max() ?? 0
        let resetPressure = resetUrgencyFactor(lines: lines, now: now)

        let raw = (average * 0.55) + (peak * 0.35) + (resetPressure * 0.10)
        let score = Int(min(100, max(0, (raw * 100).rounded())))

        let level: UsagePressureLevel
        switch score {
        case 80...: level = .high
        case 55...: level = .medium
        default: level = .low
        }

        return UsagePressureSnapshot(
            score: score,
            level: level,
            nextReset: nearestReset(in: lines, now: now)
        )
    }

    private static func resetUrgencyFactor(lines: [ExactUsageLine], now: Date) -> Double {
        let intervals = lines.compactMap { line -> Double? in
            guard let resetsAt = line.resetsAt else { return nil }
            let remaining = resetsAt.timeIntervalSince(now)
            guard remaining > 0 else { return nil }
            return remaining
        }
        guard let shortest = intervals.min() else { return 0 }
        let hours = shortest / 3600
        if hours <= 2 { return 1 }
        if hours <= 8 { return 0.65
        }
        if hours <= 24 { return 0.35 }
        return 0.1
    }

    private static func nearestReset(in lines: [ExactUsageLine], now: Date) -> Date? {
        lines.compactMap(\.resetsAt)
            .filter { $0 > now }
            .min()
    }
}
