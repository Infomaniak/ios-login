// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "InfomaniakLogin",
        platforms: [
            .iOS(.v12),
            .macOS(.v11)
        ],
        products: [
            .library(
                    name: "InfomaniakLogin",
                    targets: ["InfomaniakLogin"]),
        ],
        dependencies: [
            .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "2.0.0")),
        ],
        targets: [
            .target(
                    name: "InfomaniakLogin",
                    dependencies: [
                        .product(name: "InfomaniakDI", package: "ios-dependency-injection"),
                    ]),
            .testTarget(
                    name: "InfomaniakLoginTests",
                    dependencies: ["InfomaniakLogin"]),
        ]
)
