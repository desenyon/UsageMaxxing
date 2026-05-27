import Foundation
import Testing
@testable import UsageMaxxingCore

@Suite("UsagePressureCalculator")
struct UsagePressureCalculatorTests {
    @Test("high usage raises pressure score")
    func highUsageRaisesScore() {
        let snapshot = ExactUsageSnapshot(
            generatedAt: Date(),
            results: [
                ExactProviderResult(
                    provider: "codex",
                    installed: true,
                    status: "ok",
                    plan: "Plus",
                    lines: [
                        ExactUsageLine(
                            type: "progress",
                            label: "Session",
                            used: 96,
                            limit: 100,
                            resetsAt: Date().addingTimeInterval(3600),
                            value: nil,
                            text: nil,
                            format: ExactUsageFormat(kind: "percent")
                        )
                    ],
                    error: nil
                )
            ]
        )

        let pressure = UsagePressureCalculator.calculate(from: snapshot)
        #expect(pressure.score >= 80)
        #expect(pressure.level == .high)
    }

    @Test("low usage stays low pressure")
    func lowUsageStaysLow() {
        let snapshot = ExactUsageSnapshot(
            generatedAt: Date(),
            results: [
                ExactProviderResult(
                    provider: "cursor",
                    installed: true,
                    status: "ok",
                    plan: nil,
                    lines: [
                        ExactUsageLine(
                            type: "progress",
                            label: "Total",
                            used: 6,
                            limit: 100,
                            resetsAt: Date().addingTimeInterval(86400),
                            value: nil,
                            text: nil,
                            format: ExactUsageFormat(kind: "percent")
                        )
                    ],
                    error: nil
                )
            ]
        )

        let pressure = UsagePressureCalculator.calculate(from: snapshot)
        #expect(pressure.score < 55)
        #expect(pressure.level == .low)
    }
}
