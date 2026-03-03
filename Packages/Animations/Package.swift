// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Animations",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "Animations", targets: ["Animations"])],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../CoreUI"),
    ],
    targets: [
        .target(
            name: "Animations",
            dependencies: [
                .product(name: "CoreKit", package: "CoreKit"),
                .product(name: "CoreUI", package: "CoreUI"),
            ],
            resources: [.process("../../Shaders")]
        )
    ]
)
