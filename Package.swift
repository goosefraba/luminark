// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Luminark",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "Luminark",
            targets: ["LuminarkApp"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "LuminarkApp",
            path: "Sources/LuminarkApp",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
