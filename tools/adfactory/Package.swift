// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "adfactory",
    platforms: [.macOS("15.4")],
    targets: [
        .executableTarget(name: "adfactory"),
        .executableTarget(name: "scenegen"),
    ]
)
