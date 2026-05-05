// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "EgressBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "EgressBar",
            targets: ["EgressBar"]
        )
    ],
    targets: [
        .executableTarget(
            name: "EgressBar"
        )
    ]
)
