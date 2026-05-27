import SwiftUI
import UsageMaxxingCore

struct ExactProviderCardView: View {
    let provider: ExactProviderResult
    let compactMode: Bool
    let isLive: Bool
    @AppStorage("privacyMode") private var privacyMode = true
    @AppStorage("showPredictiveInsights") private var showPredictiveInsights = true
    @State private var isExpanded = false

    private var primaryLine: ExactUsageLine? {
        provider.lines.first(where: { $0.type == "progress" }) ?? provider.lines.first
    }

    private var cardIntensity: UsageIntensity {
        let percentLines = provider.lines.filter { $0.limit == 100 || ($0.limit ?? 0) > 0 }
        let intensities = percentLines.map { UsageIntensity.from(used: $0.used, limit: $0.limit) }
        if intensities.contains(.critical) { return .critical }
        if intensities.contains(.warning) { return .warning }
        if intensities.contains(.healthy) { return .healthy }
        return .unknown
    }

    var body: some View {
        if compactMode {
            compactCard
        } else {
            fullCard
        }
    }

    private var compactCard: some View {
        HStack(spacing: 10) {
            rail
            VStack(alignment: .leading, spacing: 2) {
                Text(DashboardTheme.displayName(for: provider.provider))
                    .font(.system(size: 12, weight: .bold))
                if let line = primaryLine {
                    Text(compactSummary(for: line))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            if let line = primaryLine {
                Text(maskedCompactValue(for: line))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DashboardTheme.color(for: UsageIntensity.from(used: line.used, limit: line.limit)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(cardBackground)
    }

    private var fullCard: some View {
        HStack(spacing: 0) {
            rail
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 6) {
                headerRow

                if isExpanded {
                    ForEach(Array(provider.lines.enumerated()), id: \.offset) { _, line in
                        ExactUsageLineView(
                            line: line,
                            provider: provider.provider,
                            isLive: isLive,
                            privacyMode: privacyMode,
                            showPredictiveInsights: showPredictiveInsights
                        )
                    }
                } else if let line = primaryLine {
                    ExactUsageLineView(
                        line: line,
                        provider: provider.provider,
                        isLive: isLive,
                        privacyMode: privacyMode,
                        showPredictiveInsights: showPredictiveInsights
                    )
                    if provider.lines.count > 1 {
                        Text("+\(provider.lines.count - 1) more metrics")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 9)
            .padding(.vertical, 8)
        }
        .background(cardBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            guard provider.lines.count > 1 else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                isExpanded.toggle()
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(DashboardTheme.displayName(for: provider.provider))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary.opacity(0.95 + cardIntensity.visualWeight * 0.05))

            Image(systemName: "checkmark.seal")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary.opacity(0.75))
                .help("Exact local plugin data")

            if let plan = provider.plan {
                Text(plan)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 4)

            if provider.lines.count > 1 {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var rail: some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(DashboardTheme.railColor(for: provider.provider))
            .frame(width: 3)
            .padding(.leading, 8)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(DashboardTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(DashboardTheme.cardBorder)
            )
    }

    private func compactSummary(for line: ExactUsageLine) -> String {
        let label = line.label ?? line.type.capitalized
        if let resetsAt = line.resetsAt {
            return "\(label.lowercased()) · resets \(UsageDateFormatting.relativeString(for: resetsAt))"
        }
        return label.lowercased()
    }

    private func maskedCompactValue(for line: ExactUsageLine) -> String {
        if privacyMode { return "•••" }
        return compactValue(for: line)
    }

    private func compactValue(for line: ExactUsageLine) -> String {
        if let value = line.value { return value }
        guard let used = line.used, let limit = line.limit, limit > 0 else { return "—" }
        if line.format?.kind == "percent" || limit == 100 {
            return "\(Int(used.rounded()))%"
        }
        return "\(Int(used.rounded()))/\(Int(limit.rounded()))"
    }
}

private struct ExactUsageLineView: View {
    let line: ExactUsageLine
    let provider: String
    var isLive: Bool = false
    var privacyMode: Bool = false
    var showPredictiveInsights: Bool = true

    private var intensity: UsageIntensity {
        UsageIntensity.from(used: line.used, limit: line.limit)
    }

    private var insight: UsageLineInsight {
        UsageLineAnalytics.insight(
            for: line,
            provider: provider,
            labelKey: line.label ?? line.type,
            previousUsed: UsageSyncHistory.shared.previousUsed(
                provider: provider,
                label: line.label ?? line.type
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(metricTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.55 + intensity.visualWeight * 0.45))
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(valueText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DashboardTheme.color(for: intensity).opacity(0.65 + intensity.visualWeight * 0.35))
            }

            if line.type == "progress", let used = line.used, let limit = line.limit, limit > 0 {
                UsageProgressBar(
                    fraction: min(max(used / limit, 0), 1),
                    intensity: intensity,
                    isLive: isLive
                )
                .opacity(0.55 + intensity.visualWeight * 0.45)
            }

            insightFooter
        }
    }

    private var metricTitle: String {
        let label = line.label ?? line.type.capitalized
        if let resetsAt = line.resetsAt {
            return "\(label) · resets \(UsageDateFormatting.relativeString(for: resetsAt))"
        }
        return label
    }

    @ViewBuilder
    private var insightFooter: some View {
        let notes = showPredictiveInsights
            ? [insight.statusNote, insight.depletionEstimate, insight.velocityNote].compactMap { $0 }
            : []
        if notes.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(notes, id: \.self) { note in
                    Text(note)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(noteColor(for: note))
                        .lineLimit(1)
                }
            }
        }
    }

    private func noteColor(for note: String) -> Color {
        if note.contains("depletion") || note.contains("High burn") || note.contains("exhausted") {
            return DashboardTheme.warning.opacity(0.9)
        }
        if note.contains("Safe") {
            return DashboardTheme.healthy.opacity(0.85)
        }
        return Color.secondary.opacity(0.75)
    }

    private var valueText: String {
        if privacyMode { return "•••" }
        if let value = line.value { return value }
        if let text = line.text { return text }
        guard let used = line.used, let limit = line.limit else { return "Live" }
        switch line.format?.kind {
        case "percent":
            return "\(used.formatted(.number.precision(.fractionLength(0...1))))%"
        case "dollars":
            return "$\(used.formatted(.number.precision(.fractionLength(0...2)))) / $\(limit.formatted(.number.precision(.fractionLength(0...2))))"
        default:
            if limit == 100 {
                return "\(used.formatted(.number.precision(.fractionLength(0...1))))%"
            }
            return "\(used.formatted(.number.precision(.fractionLength(0...1)))) / \(limit.formatted(.number.precision(.fractionLength(0...1))))"
        }
    }
}
