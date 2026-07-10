// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SBNetworking",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "SBNetworking",
            targets: ["SBNetworking"]),
    ],
    targets: [
        .target(
            name: "SBNetworking",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]),
        .testTarget(
            name: "SBNetworkingTests",
            dependencies: ["SBNetworking"],
            resources: [
                .process("Resources/")
            ]
        ),
    ]
)
