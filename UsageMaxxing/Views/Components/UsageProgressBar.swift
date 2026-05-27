import SwiftUI
import UsageMaxxingCore

struct UsageProgressBar: View {
    let fraction: Double
    let intensity: UsageIntensity
    var isLive: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fillWidth = max(0, min(width * fraction, width))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DashboardTheme.trackBackground)

                Capsule()
                    .fill(fillGradient)
                    .frame(width: fillWidth)
                    .shadow(
                        color: DashboardTheme.color(for: intensity).opacity(intensity == .critical ? 0.5 : 0.18),
                        radius: intensity == .critical ? 4 : 1.5
                    )

                if isLive, fillWidth > 4 {
                    TimelineView(.animation(minimumInterval: 0.12, paused: false)) { timeline in
                        let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.2) / 2.2
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.28), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(fillWidth * 0.45, 56))
                            .offset(x: CGFloat(phase) * max(fillWidth - 24, 0))
                            .blendMode(.screen)
                    }
                    .frame(width: fillWidth, alignment: .leading)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(height: 4)
        .animation(.easeInOut(duration: 0.35), value: fraction)
    }

    private var fillGradient: LinearGradient {
        let base = DashboardTheme.color(for: intensity)
        return LinearGradient(
            colors: [base.opacity(0.82), base],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
