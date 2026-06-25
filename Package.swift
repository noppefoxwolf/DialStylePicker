// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DialStylePicker",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "DialStylePicker",
            targets: ["DialStylePicker"]
        ),
    ],
    targets: [
        .target(
            name: "DialStylePicker",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "DialStylePickerTests",
            dependencies: ["DialStylePicker"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ],
    swiftLanguageModes: [.v6]
)
