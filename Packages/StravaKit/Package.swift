// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "StravaKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "StravaKit",
            targets: ["StravaKit"]
        ),
    ],
    dependencies: [
        .package(path: "../CoreKit"),
    ],
    targets: [
        .target(
            name: "StravaKit",
            dependencies: [.product(name: "CoreKit", package: "CoreKit")]
        ),
    ]
)
