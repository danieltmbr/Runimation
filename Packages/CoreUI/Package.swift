// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CoreUI",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "CoreUI", targets: ["CoreUI"])],
    dependencies: [.package(path: "../CoreKit")],
    targets: [
        .target(
            name: "CoreUI",
            dependencies: [.product(name: "CoreKit", package: "CoreKit")]
        )
    ]
)
