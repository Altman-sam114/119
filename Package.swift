// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RomeLegions",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RomeLegionsCore",
            targets: ["RomeLegionsCore"]
        )
    ],
    targets: [
        .target(
            name: "RomeLegionsCore",
            path: "Sources/RomeLegionsCore"
        ),
        .testTarget(
            name: "RomeLegionsCoreTests",
            dependencies: ["RomeLegionsCore"],
            path: "Tests/RomeLegionsCoreTests"
        )
    ]
)
