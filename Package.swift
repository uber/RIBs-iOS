// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "RIBs",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "RIBs", targets: ["RIBs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.9.0"),
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.2.2"), // for testTarget only
    ],
    targets: [
        .target(
            name: "RIBs",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift")
            ],
            path: "RIBs"
        ),
        .testTarget(
            name: "RIBsTests",
            dependencies: ["RIBs", "CwlPreconditionTesting"],
            path: "RIBsTests"
        ),
    ]
)
