// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "MonkeyBrowser",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "MonkeyBrowser", targets: ["MonkeyBrowser"])
    ],
    dependencies: [
        // MobileVLCKit for video playback
        .package(url: "https://github.com/nicklama/MobileVLCKit.git", from: "3.5.0"),
        // Tampermonkey script engine support
        .package(url: "https://github.com/nicklama/Tampermonkey.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MonkeyBrowser",
            dependencies: ["MobileVLCKit"],
            path: "MonkeyBrowser/Sources"
        )
    ]
)
