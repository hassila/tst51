// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tst51",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "1.0.0-alpha"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "server",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Lifecycle", package: "swift-service-lifecycle"),
                .product(name: "LifecycleNIOCompat", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "NIO", package: "swift-nio"),
            ],
            path: "Sources/tst51/Server"),
        .target(
            name: "client",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Lifecycle", package: "swift-service-lifecycle"),
                .product(name: "LifecycleNIOCompat", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "NIO", package: "swift-nio"),
            ],
            path: "Sources/tst51/Client"),
        .testTarget(
            name: "tst51Tests",
            dependencies: ["server"]),
    ]
)
