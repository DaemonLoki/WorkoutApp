// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "OnlyWorkoutKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v27), .watchOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "OnlyWorkoutCore", targets: ["OnlyWorkoutCore"]),
        .library(name: "OnlyWorkoutStore", targets: ["OnlyWorkoutStore"]),
        .library(name: "OnlyWorkoutDesign", targets: ["OnlyWorkoutDesign"]),
        .library(name: "OnlyWorkoutLiveActivity", targets: ["OnlyWorkoutLiveActivity"]),
    ],
    targets: [
        .target(name: "OnlyWorkoutCore"),
        .target(name: "OnlyWorkoutStore", dependencies: ["OnlyWorkoutCore"]),
        .target(name: "OnlyWorkoutDesign", dependencies: ["OnlyWorkoutCore"]),
        .target(name: "OnlyWorkoutLiveActivity"),
        .testTarget(name: "OnlyWorkoutCoreTests", dependencies: ["OnlyWorkoutCore"]),
        .testTarget(name: "OnlyWorkoutStoreTests", dependencies: ["OnlyWorkoutStore"]),
    ]
)
