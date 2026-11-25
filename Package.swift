// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "MacWallspace",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "MacWallspace", targets: ["MacWallspace"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacWallspace",
            dependencies: [],
            path: "Sources/MacWallspace"
        )
    ]
)
