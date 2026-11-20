// swift-tools-version: 6.4

import PackageDescription

let settings: [SwiftSetting] = [
    .enableUpcomingFeature("ApproachableConcurrency"),
    .defaultIsolation(MainActor.self),
]

let package = Package(
    name: "Truss",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "Truss", targets: ["Truss"]),
    ],
    targets: [
        .target(name: "Truss", swiftSettings: settings),
    ]
)
