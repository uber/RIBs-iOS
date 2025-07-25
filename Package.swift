// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "RIBs",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "RIBs", targets: ["RIBs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.2.2"), // for testTarget only
    ],
    targets: [
        .target(
            name: "RIBs",
            dependencies: [],
            path: "RIBs"
        ),
        .testTarget(
            name: "RIBsTests",
            dependencies: ["RIBs", "CwlPreconditionTesting"],
            path: "RIBsTests"
        ),
    ]
)
