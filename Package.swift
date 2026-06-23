// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VibeAwake",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "VibeAwake",
            path: "Sources"
        )
    ]
)
