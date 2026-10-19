// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FTEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FTEngine", targets: ["FTEngine"])
    ],
    targets: [
        .target(name: "FTEngine"),
        .testTarget(name: "FTEngineTests", dependencies: ["FTEngine"])
    ]
)
