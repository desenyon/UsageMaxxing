import Foundation

public enum AppInfo {
    public static let version = "1.1.0"
    public static let build = "2"
    public static let fullVersion = "\(version) (\(build))"

    public static let repositoryURL = URL(string: "https://github.com/desenyon/UsageMaxxing")!
    public static let releasesURL = URL(string: "https://github.com/desenyon/UsageMaxxing/releases")!

    public static let pluginDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/com.sunstory.openusage/plugins", isDirectory: true)
        .path
}
