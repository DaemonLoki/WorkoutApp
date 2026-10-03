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
        .library(name: "OnlyWorkoutConnectivity", targets: ["OnlyWorkoutConnectivity"]),
        .library(name: "OnlyWorkoutSync", targets: ["OnlyWorkoutSync"]),
    ],
    dependencies: [
        // The only third-party dependency (README §2); imported by OnlyWorkoutSync alone.
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.55.3")
    ],
    targets: [
        .target(name: "OnlyWorkoutCore"),
        .target(name: "OnlyWorkoutStore", dependencies: ["OnlyWorkoutCore"]),
        .target(name: "OnlyWorkoutDesign", dependencies: ["OnlyWorkoutCore"]),
        .target(name: "OnlyWorkoutLiveActivity"),
        .target(name: "OnlyWorkoutConnectivity", dependencies: ["OnlyWorkoutCore", "OnlyWorkoutStore"]),
        // iOS only in practice: the Watch app never links it (ADR-0002).
        .target(
            name: "OnlyWorkoutSync",
            dependencies: ["OnlyWorkoutStore", .product(name: "Supabase", package: "supabase-swift")]),
        .testTarget(name: "OnlyWorkoutCoreTests", dependencies: ["OnlyWorkoutCore"]),
        .testTarget(name: "OnlyWorkoutStoreTests", dependencies: ["OnlyWorkoutStore"]),
        .testTarget(name: "OnlyWorkoutSyncTests", dependencies: ["OnlyWorkoutSync"]),
    ]
)
