// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "DailyDesk",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DailyDesk", targets: ["DailyDesk"])
    ],
    targets: [
        .executableTarget(
            name: "DailyDesk",
            path: "Sources/DailyDesk"
        )
    ]
)

