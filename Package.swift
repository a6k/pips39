// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pips39Core",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "Pips39Core", targets: ["Pips39Core"])
    ],
    targets: [
        .target(
            name: "Pips39Core",
            resources: [
                .copy("Resources/english.txt"),
                .process("Localization")
            ]
        ),
        .testTarget(
            name: "Pips39CoreTests",
            dependencies: ["Pips39Core"],
            resources: [
                .copy("Resources/vectors.json"),
                .copy("Resources/coleman-vectors.json")
            ]
        )
    ]
)
