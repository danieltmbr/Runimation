// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Visualiser",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "Visualiser", targets: ["Visualiser"])],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../CoreUI"),
    ],
    targets: [
        .target(
            name: "Visualiser",
            dependencies: [
                .product(name: "CoreKit", package: "CoreKit"),
                .product(name: "CoreUI", package: "CoreUI"),
            ],
            resources: [.process("Resources/Shaders")]
        )
    ]
)
