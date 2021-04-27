// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReactiveAPI",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "ReactiveAPI",  targets: ["ReactiveAPI"]),
        .library(name: "ReactiveAPIExt", targets: ["ReactiveAPIExt"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.0.0"),
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter", from: "1.5.0"),
        .package(name: "CombineExt", url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ReactiveAPI",
            dependencies: []),
        .target(
            name: "ReactiveAPIExt",
            dependencies: ["CombineExt"]),
        .testTarget(
            name: "ReactiveAPITests",
            dependencies: [
                "ReactiveAPI",
                "Swifter",
                "OHHTTPStubs",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
            ]),
        .testTarget(
            name: "ReactiveAPIExtTests",
            dependencies: [
                "ReactiveAPIExt",
                "CombineExt"
            ]),
    ]
)
