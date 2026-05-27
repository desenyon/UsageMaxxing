import Foundation

public enum UsageIntensity: String, Sendable, Equatable {
    case critical
    case warning
    case healthy
    case unknown

    public static func from(used: Double?, limit: Double?) -> UsageIntensity {
        guard let used, let limit, limit > 0 else { return .unknown }
        let ratio = used / limit
        if ratio >= 0.9 { return .critical }
        if ratio >= 0.75 { return .warning }
        return .healthy
    }

    public var visualWeight: Double {
        switch self {
        case .critical: 1.0
        case .warning: 0.72
        case .healthy: 0.45
        case .unknown: 0.3
        }
    }
}
