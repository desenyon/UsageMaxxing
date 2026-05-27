import Foundation

public struct ExactUsageSnapshot: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let results: [ExactProviderResult]
}

public struct ExactProviderResult: Codable, Equatable, Sendable {
    public let provider: String
    public let installed: Bool
    public let status: String
    public let plan: String?
    public let lines: [ExactUsageLine]
    public let error: String?
}

public struct ExactUsageLine: Codable, Equatable, Sendable {
    public let type: String
    public let label: String?
    public let used: Double?
    public let limit: Double?
    public let resetsAt: Date?
    public let value: String?
    public let text: String?
    public let format: ExactUsageFormat?
}

public struct ExactUsageFormat: Codable, Equatable, Sendable {
    public let kind: String?
}

public enum ExactUsageBridgeError: Error, LocalizedError {
    case nodeUnavailable
    case scriptMissing
    case bridgeFailed(String)
    case invalidOutput

    public var errorDescription: String? {
        switch self {
        case .nodeUnavailable:
            "Node.js is required to run installed-app exact usage plugins."
        case .scriptMissing:
            "Exact usage bridge script is missing from the app bundle."
        case .bridgeFailed(let message):
            message
        case .invalidOutput:
            "Exact usage bridge returned invalid output."
        }
    }
}

public final class ExactUsageBridgeService {
    private let scriptURL: URL

    public init(scriptURL: URL) {
        self.scriptURL = scriptURL
    }

    public func fetch() throws -> ExactUsageSnapshot {
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            throw ExactUsageBridgeError.scriptMissing
        }
        guard let node = Self.nodePath() else {
            throw ExactUsageBridgeError.nodeUnavailable
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: node)
        process.arguments = [scriptURL.path]

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        try process.run()
        process.waitUntilExit()

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = error.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8) ?? "Exact usage bridge failed."
            throw ExactUsageBridgeError.bridgeFailed(message)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(ExactUsageSnapshot.self, from: outputData)
        } catch {
            throw ExactUsageBridgeError.invalidOutput
        }
    }

    private static func nodePath() -> String? {
        let candidates = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node"
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
