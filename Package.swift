// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kombucha",
    products: [
        .executable(
            name: "kombucha",
            targets: ["KombuchaCLI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-package-manager.git",
            .upToNextMinor(from: "0.4.0")
        ),
        .package(
            url: "https://github.com/wayfair/prelude",
            .upToNextMinor(from: "0.3.0")
        )
    ],
    targets: [
        .target(
            name: "JUnit",
            dependencies: ["Prelude"]
            ),
        .testTarget(
            name: "JUnitTests",
            dependencies: ["JUnit"]
            ),
        .target(
            name: "Cont",
            dependencies: ["Prelude"]
        ),
        .target(
            name: "JSONCheck",
            dependencies: ["JSONValue", "Prelude"]
        ),
        .testTarget(
            name: "JSONCheckTests",
            dependencies: ["JSONCheck", "Prelude"]
        ),
        .target(
            name: "JSONValue"
        ),
        .testTarget(
            name: "JSONValueTests",
            dependencies: ["JSONValue"]
        ),
        .target(
            name: "KombuchaCLI",
            dependencies: ["JSONValue", "KombuchaLib", "SPMUtility", "JUnit"]
        ),
        .target(
            name: "KombuchaLib",
            dependencies: ["Cont", "JSONCheck", "JSONValue", "Prelude", "SPMUtility"]
        ),
        .testTarget(
            name: "KombuchaLibTests",
            dependencies: ["KombuchaLib", "JSONValue"]
        )
    ]
)
