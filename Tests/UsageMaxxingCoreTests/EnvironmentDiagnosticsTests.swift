import Foundation
import Testing
@testable import UsageMaxxingCore

@Suite("EnvironmentDiagnostics")
struct EnvironmentDiagnosticsTests {
    @Test("detects missing plugin directory")
    func missingPluginDirectory() {
        let report = EnvironmentDiagnostics.evaluate(
            pluginDirectoryPath: "/tmp/usagemaxxing-missing-plugins-\(UUID().uuidString)",
            bridgeScriptPath: nil
        )
        #expect(report.pluginDirectoryExists == false)
        #expect(report.isReadyForSync == false)
    }

    @Test("marks bridge available when script path exists")
    func bridgeAvailable() throws {
        let directory = FileManager.default.temporaryDirectory
        let script = directory.appendingPathComponent("bridge-\(UUID().uuidString).mjs")
        try "export {}".write(to: script, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: script) }

        let report = EnvironmentDiagnostics.evaluate(bridgeScriptPath: script.path)
        #expect(report.bridgeScriptAvailable == true)
    }
}
