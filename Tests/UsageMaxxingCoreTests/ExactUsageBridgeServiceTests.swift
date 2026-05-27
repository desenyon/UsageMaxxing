import Foundation
import Testing
@testable import UsageMaxxingCore

@Suite("ExactUsageSnapshot")
struct ExactUsageBridgeServiceTests {
    @Test("decodes exact OpenUsage plugin output")
    func decodesExactPluginOutput() throws {
        let data = """
        {
          "generatedAt": "2026-05-27T21:05:36Z",
          "results": [
            {
              "provider": "codex",
              "installed": true,
              "status": "ok",
              "plan": "Plus",
              "lines": [
                {
                  "type": "progress",
                  "label": "Session",
                  "used": 55,
                  "limit": 100,
                  "format": { "kind": "percent" },
                  "resetsAt": "2026-05-28T01:57:54Z"
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(ExactUsageSnapshot.self, from: data)

        #expect(snapshot.results.count == 1)
        #expect(snapshot.results[0].provider == "codex")
        #expect(snapshot.results[0].lines[0].used == 55)
        #expect(snapshot.results[0].lines[0].format?.kind == "percent")
    }
}
