// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "CombineRIBs",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "CombineRIBs", targets: ["CombineRIBs"]),
    ],
    targets: [
        .target(
            name: "CombineRIBs",
            path: "CombineRIBs",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "CombineRIBsTests",
            dependencies: ["CombineRIBs"],
            path: "CombineRIBsTests",
            exclude: ["Info.plist"]
        ),
    ]
)
