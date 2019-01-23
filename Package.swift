// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Marionette",
    products: [
        .library(name: "Marionette", targets: ["Marionette"]),
    ],
    dependencies: [
        .package(url: "https://github.com/artman/Signals", from: "6.0.0"),
        .package(url: "https://github.com/LinusU/JSBridge", from: "1.0.0-alpha.13"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.0.0"),
    ],
    targets: [
        .target(name: "Marionette", dependencies: ["JSBridge", "PromiseKit", "Signals"], path: "Sources"),
        .testTarget(name: "MarionetteTests", dependencies: ["Marionette"], path: "Tests"),
    ]
)
