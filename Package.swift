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
            .package(name: "InfomaniakCoreUI", url: "https://github.com/Infomaniak/ios-core-ui.git", .upToNextMajor(from: "1.0.0")),
            .package(name: "InfomaniakCore", url: "https://github.com/Infomaniak/ios-core.git", .upToNextMajor(from: "2.0.1")),
        ],
        targets: [
            .target(
                    name: "InfomaniakLogin",
                    dependencies: [
                        "InfomaniakCore",
                        "InfomaniakCoreUI",
                    ]),
            .testTarget(
                    name: "InfomaniakLoginTests",
                    dependencies: ["InfomaniakLogin"]),
        ]
)
