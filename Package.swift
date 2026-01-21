// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Slowdown",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Slowdown",
            path: "Slowdown/Sources",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
