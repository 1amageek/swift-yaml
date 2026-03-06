// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-yaml",
    products: [
        .library(name: "YAML", targets: ["YAML"]),
    ],
    targets: [
        .target(name: "YAML"),
        .testTarget(name: "YAMLTests", dependencies: ["YAML"]),
    ]
)
