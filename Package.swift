// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CombineRIBs",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "CombineRIBs", targets: ["CombineRIBs"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CombineRIBs",
            dependencies: [],
            path: "CombineRIBs"
        ),
        .testTarget(
            name: "CombineRIBsTests",
            dependencies: ["CombineRIBs"],
            path: "CombineRIBsTests"
        ),
    ]
)
