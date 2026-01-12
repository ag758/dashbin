// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Termshelf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Termshelf", targets: ["Termshelf"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Termshelf",
            dependencies: ["SwiftTerm"],
            path: ".", // Sources are in the root directory
            exclude: ["Termshelf.entitlements"],
            resources: [
                .process("Termshelf.entitlements")
            ]
        )
    ]
)
