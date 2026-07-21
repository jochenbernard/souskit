// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SousKit",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .visionOS(.v1),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SousCore",
            targets: ["SousCore"]
        ),
        .library(
            name: "SousKit",
            targets: ["SousKit"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "SousCore",
            swiftSettings: .shared,
            plugins: .shared
        ),
        .testTarget(
            name: "SousCoreTests",
            dependencies: ["SousCore"],
            swiftSettings: .shared,
            plugins: .shared
        ),
        .target(
            name: "SousKit",
            dependencies: ["SousCore"],
            swiftSettings: .shared,
            plugins: .shared
        ),
        .testTarget(
            name: "SousKitTests",
            dependencies: ["SousKit"],
            swiftSettings: .shared,
            plugins: .shared
        )
    ],
    swiftLanguageModes: [.v6]
)

private extension [SwiftSetting] {
    static var shared: [SwiftSetting] {
        [
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault")
        ]
    }
}

private extension [Target.PluginUsage] {
    static var shared: [Target.PluginUsage] {
        [
            .plugin(
                name: "SwiftLintBuildToolPlugin",
                package: "SwiftLintPlugins"
            )
        ]
    }
}
