// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReactiveAPI",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .tvOS(.v12),
        .watchOS(.v5),
    ],
    products: [
        .library(name: "ReactiveAPI", targets: ["ReactiveAPI"]),
        .library(name: "ReactiveAPIExt", targets: ["ReactiveAPIExt"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "5.1.1"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.0.0"),
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter", from: "1.5.0-rc.1"),
    ],
    targets: [
        .target(
            name: "ReactiveAPI",
            dependencies: [
                "RxSwift",
                .product(name: "RxCocoa", package: "RxSwift"),
            ]),
        .target(
            name: "ReactiveAPIExt",
            dependencies: ["RxSwift"]),
        .testTarget(
            name: "ReactiveAPITests",
            dependencies: [
                "ReactiveAPI",
                "Swifter",
                "OHHTTPStubs",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
                .product(name: "RxBlocking", package: "RxSwift"),
            ]),
        .testTarget(
            name: "ReactiveAPIExtTests",
            dependencies: [
                "ReactiveAPI",
                "ReactiveAPIExt",
                .product(name: "RxBlocking", package: "RxSwift"),
            ]),
    ]
)
