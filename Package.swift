// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftGodotBuilderExample",
    platforms: [.macOS(.v14), .custom("Windows", versionString: "11")],
    products: [
        .library(
            name: "SwiftGodotBuilderExample",
            type: .dynamic,
            targets: ["SwiftGodotBuilderExample"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", revision: "20d2d7a35d2ad392ec556219ea004da14ab7c1d4"),
        .package(url: "https://github.com/johnsusek/SwiftGodotBuilder", branch: "main"),
    ],
    targets: [
        .target(
            name: "SwiftGodotBuilderExample",
            dependencies: ["SwiftGodot", "SwiftGodotBuilder"]
        ),
    ]
)
