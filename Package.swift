// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "InfomaniakLogin",
        platforms: [
            .iOS(.v13),
        ],
        products: [
            .library(
                    name: "InfomaniakLogin",
                    targets: ["InfomaniakLogin"]),
        ],
        dependencies: [
            .package(url: "https://github.com/Infomaniak/ios-core-ui", .upToNextMajor(from: "1.1.0")),
        ],
        targets: [
            .target(
                    name: "InfomaniakLogin",
                    dependencies: [
                        .product(name: "InfomaniakCoreUI", package: "ios-core-ui"),
                    ]),
            .testTarget(
                    name: "InfomaniakLoginTests",
                    dependencies: ["InfomaniakLogin"]),
        ]
)
