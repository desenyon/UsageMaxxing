import Foundation

public struct UsageLineInsight: Equatable, Sendable {
    public let depletionEstimate: String?
    public let velocityNote: String?
    public let statusNote: String?

    public init(depletionEstimate: String?, velocityNote: String?, statusNote: String?) {
        self.depletionEstimate = depletionEstimate
        self.velocityNote = velocityNote
        self.statusNote = statusNote
    }
}

public enum UsageLineAnalytics {
    public static func insight(
        for line: ExactUsageLine,
        provider: String,
        labelKey: String,
        now: Date = Date(),
        previousUsed: Double?
    ) -> UsageLineInsight {
        let intensity = UsageIntensity.from(used: line.used, limit: line.limit)
        let depletion = depletionEstimate(for: line, now: now)
        let velocity = velocityNote(current: line.used, previous: previousUsed)
        let status = statusNote(intensity: intensity, line: line, now: now)
        _ = provider
        _ = labelKey
        return UsageLineInsight(
            depletionEstimate: depletion,
            velocityNote: velocity,
            statusNote: status
        )
    }

    public static func depletionEstimate(for line: ExactUsageLine, now: Date = Date()) -> String? {
        guard line.type == "progress",
              let used = line.used,
              let limit = line.limit,
              limit > 0,
              let resetsAt = line.resetsAt,
              used > 0,
              used < limit else {
            return nil
        }

        let remaining = resetsAt.timeIntervalSince(now)
        guard remaining > 0 else { return nil }

        let ratio = used / limit
        guard ratio > 0 else { return nil }

        let secondsToFull = remaining * (1 - ratio) / ratio
        guard secondsToFull.isFinite, secondsToFull > 0, secondsToFull < 60 * 60 * 24 * 14 else {
            return nil
        }

        return "Est. depletion \(UsageDurationFormatting.compactInterval(secondsToFull))"
    }

    public static func velocityNote(current: Double?, previous: Double?) -> String? {
        guard let current, let previous, previous > 0 else { return nil }
        let delta = ((current - previous) / previous) * 100
        guard abs(delta) >= 3 else { return nil }
        let sign = delta >= 0 ? "+" : ""
        return "Velocity \(sign)\(Int(delta.rounded()))% vs last sync"
    }

    public static func statusNote(intensity: UsageIntensity, line: ExactUsageLine, now: Date = Date()) -> String? {
        switch intensity {
        case .critical:
            return "Quota nearly exhausted"
        case .warning:
            if let resetsAt = line.resetsAt, resetsAt.timeIntervalSince(now) < 6 * 3600 {
                return "High burn session detected"
            }
            return "Approaching limit"
        case .healthy:
            if let used = line.used, let limit = line.limit, limit > 0, used / limit < 0.35 {
                return "Safe until reset"
            }
            return nil
        case .unknown:
            return nil
        }
    }
}

public enum UsageDurationFormatting {
    public static func compactInterval(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(1, Int(seconds / 60))
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }
}
