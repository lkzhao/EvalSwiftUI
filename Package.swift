// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "EvalSwiftUI",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .macCatalyst(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EvalSwiftUI",
            targets: ["EvalSwiftUI"]
        ),
        .library(
            name: "EvalSwiftIR",
            targets: ["EvalSwiftIR"]
        ),
        .library(
            name: "EvalSwiftRuntime",
            targets: ["EvalSwiftRuntime"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0-latest"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "EvalSwiftIR",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                "Macros"
            ]
        ),
        .macro(
            name: "Macros",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        .target(
            name: "EvalSwiftRuntime",
            dependencies: [
                "EvalSwiftIR"
            ]
        ),
        .target(
            name: "EvalSwiftUI",
            dependencies: [
                "EvalSwiftRuntime"
            ]
        ),
        .testTarget(
            name: "EvalSwiftRuntimeTests",
            dependencies: [
                "EvalSwiftRuntime",
                "EvalSwiftIR"
            ]
        ),
    ]
)
