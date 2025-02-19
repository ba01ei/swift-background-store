// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-background-store",
    platforms: [
      .iOS(.v14),
      .macOS(.v10_15),
      .tvOS(.v14),
      .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BackgroundStore",
            targets: ["BackgroundStore"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "BackgroundStore"),
        .testTarget(
            name: "BackgroundStoreTests",
            dependencies: ["BackgroundStore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
