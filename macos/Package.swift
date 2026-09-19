// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "spinCD",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0")
    ],
    targets: [
        .executableTarget(
            name: "spinCD",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "spinCDTests",
            dependencies: ["spinCD"]
        ),
    ]
)
