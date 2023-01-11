// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "InfomaniakLogin",
        platforms: [
            .iOS(.v12),
        ],
        products: [
            .library(
                    name: "InfomaniakLogin",
                    targets: ["InfomaniakLogin"]),
        ],
        dependencies: [
            .package(name: "InfomaniakCore", url: "https://github.com/Infomaniak/ios-core.git", .upToNextMajor(from: "2.0.0")),
            .package(name: "InfomaniakCoreUI", url: "https://github.com/Infomaniak/ios-core-ui.git", .upToNextMajor(from: "1.0.0")),
            .package(url: "https://github.com/onevcat/Kingfisher", .upToNextMajor(from: "7.0.0")),
        ],
        targets: [
            .target(
                    name: "InfomaniakLogin",
                    dependencies: [
                        "InfomaniakCore",
                        "Kingfisher",
                    ]),
            .testTarget(
                    name: "InfomaniakLoginTests",
                    dependencies: ["InfomaniakLogin"]),
        ]
)
