// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KDBXSync",

    platforms: [
    .macOS(.v13)
    ],

    dependencies: [
        .package(
            url: "https://github.com/mattt/swift-toml.git",
            from: "2.0.0"
        )
    ],

    targets: [
        .executableTarget(
            name: "KDBXSync",
            dependencies: [
                .product(
                    name: "TOML",
                    package: "swift-toml"
                )
            ]
        )
    ]
)
