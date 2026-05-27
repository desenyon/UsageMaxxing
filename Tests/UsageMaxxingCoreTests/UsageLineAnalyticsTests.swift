import Foundation
import Testing
@testable import UsageMaxxingCore

@Suite("UsageLineAnalytics")
struct UsageLineAnalyticsTests {
    @Test("estimates depletion before reset")
    func estimatesDepletion() {
        let line = ExactUsageLine(
            type: "progress",
            label: "Session",
            used: 80,
            limit: 100,
            resetsAt: Date().addingTimeInterval(4 * 3600),
            value: nil,
            text: nil,
            format: ExactUsageFormat(kind: "percent")
        )

        let estimate = UsageLineAnalytics.depletionEstimate(for: line)
        #expect(estimate?.contains("Est. depletion") == true)
    }

    @Test("marks healthy usage as safe")
    func safeUntilReset() {
        let line = ExactUsageLine(
            type: "progress",
            label: "Weekly",
            used: 20,
            limit: 100,
            resetsAt: Date().addingTimeInterval(48 * 3600),
            value: nil,
            text: nil,
            format: ExactUsageFormat(kind: "percent")
        )

        let insight = UsageLineAnalytics.insight(
            for: line,
            provider: "cursor",
            labelKey: "weekly",
            previousUsed: 15
        )
        #expect(insight.statusNote == "Safe until reset")
    }
}
