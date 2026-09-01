// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Niulai",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Niulai",
            path: "Sources/Niulai",
            resources: [.process("Resources")]
        )
    ]
)
