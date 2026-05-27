import Foundation

public struct EnvironmentDiagnosticReport: Equatable, Sendable {
    public let nodePath: String?
    public let pluginDirectoryExists: Bool
    public let pluginDirectoryPath: String
    public let installedPluginCount: Int
    public let bridgeScriptAvailable: Bool

    public var isReadyForSync: Bool {
        nodePath != nil && pluginDirectoryExists && bridgeScriptAvailable
    }

    public init(
        nodePath: String?,
        pluginDirectoryExists: Bool,
        pluginDirectoryPath: String,
        installedPluginCount: Int,
        bridgeScriptAvailable: Bool
    ) {
        self.nodePath = nodePath
        self.pluginDirectoryExists = pluginDirectoryExists
        self.pluginDirectoryPath = pluginDirectoryPath
        self.installedPluginCount = installedPluginCount
        self.bridgeScriptAvailable = bridgeScriptAvailable
    }
}

public enum EnvironmentDiagnostics {
    private static let nodeCandidates = [
        "/opt/homebrew/bin/node",
        "/usr/local/bin/node",
        "/usr/bin/node"
    ]

    public static func evaluate(
        pluginDirectoryPath: String = AppInfo.pluginDirectory,
        bridgeScriptPath: String? = nil
    ) -> EnvironmentDiagnosticReport {
        let nodePath = nodeCandidates.first { FileManager.default.isExecutableFile(atPath: $0) }
        let pluginURL = URL(fileURLWithPath: pluginDirectoryPath, isDirectory: true)
        let pluginExists = FileManager.default.fileExists(atPath: pluginDirectoryPath)
        let pluginCount = (try? FileManager.default.contentsOfDirectory(atPath: pluginDirectoryPath).count) ?? 0

        let bridgeAvailable: Bool
        if let bridgeScriptPath {
            bridgeAvailable = FileManager.default.isReadableFile(atPath: bridgeScriptPath)
        } else {
            bridgeAvailable = false
        }

        _ = pluginURL
        return EnvironmentDiagnosticReport(
            nodePath: nodePath,
            pluginDirectoryExists: pluginExists,
            pluginDirectoryPath: pluginDirectoryPath,
            installedPluginCount: pluginCount,
            bridgeScriptAvailable: bridgeAvailable
        )
    }
}
