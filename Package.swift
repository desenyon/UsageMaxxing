// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UsageMaxxing",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "UsageMaxxing", targets: ["UsageMaxxing"]),
        .library(name: "UsageMaxxingCore", targets: ["UsageMaxxingCore"])
    ],
    targets: [
        .target(
            name: "UsageMaxxingCore",
            path: "UsageMaxxingCore"
        ),
        .executableTarget(
            name: "UsageMaxxing",
            dependencies: ["UsageMaxxingCore"],
            path: "UsageMaxxing",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "UsageMaxxingCoreTests",
            dependencies: ["UsageMaxxingCore"],
            path: "Tests/UsageMaxxingCoreTests"
        )
    ]
)
