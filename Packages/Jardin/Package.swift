// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Jardin",
    defaultLocalization: "fr",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "JardinCore", targets: ["JardinCore"]),
        .library(name: "JardinML", targets: ["JardinML"]),
        .library(name: "JardinUI", targets: ["JardinUI"]),
    ],
    targets: [
        .target(name: "JardinCore"),
        .target(name: "JardinML", dependencies: ["JardinCore"]),
        .target(name: "JardinUI", dependencies: ["JardinCore", "JardinML"]),
        .testTarget(name: "JardinCoreTests", dependencies: ["JardinCore"]),
        .testTarget(name: "JardinMLTests", dependencies: ["JardinML"]),
    ]
)
