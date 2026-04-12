// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VisualiserUI",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "VisualiserUI", targets: ["VisualiserUI"])],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../CoreUI"),
    ],
    targets: [
        .target(
            name: "VisualiserUI",
            dependencies: [
                .product(name: "CoreKit", package: "CoreKit"),
                .product(name: "CoreUI", package: "CoreUI"),
            ],
            resources: [.process("Resources/Shaders")]
        )
    ]
)
