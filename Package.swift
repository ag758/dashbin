// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Dashbin",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Dashbin", targets: ["Dashbin"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Dashbin",
            dependencies: ["SwiftTerm"],
            path: ".", // Sources are in the root directory
            exclude: ["Dashbin.entitlements"],
            resources: [
                .process("Dashbin.entitlements"),
                .process("Assets.xcassets")
            ]
        )
    ]
)
