// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SousKit",
    products: [
        .library(
            name: "SousKit",
            targets: ["SousKit"]
        )
    ],
    targets: [
        .target(
            name: "SousKit",
            swiftSettings: [
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
