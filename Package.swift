// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TypeBuilder",
    products: [
        .library(
            name: "TypeBuilder",
            targets: ["TypeBuilder"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TypeBuilder",
            dependencies: []),
        .testTarget(
            name: "TypeBuilderTests",
            dependencies: ["TypeBuilder"]),
    ]
)
