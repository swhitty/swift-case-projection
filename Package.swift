// swift-tools-version:6.1

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-case-projection",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "CaseProjection",
            targets: ["CaseProjection"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", "510.0.0"..<"602.0.0")
    ],
    targets: [
        .target(
            name: "CaseProjection",
            dependencies: ["MacroPlugin"],
            path: "Sources",
            swiftSettings: .upcomingFeatures
        ),
        .macro(
            name: "MacroPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Plugin",
            swiftSettings: .upcomingFeatures
        ),
        .testTarget(
            name: "CaseProjectionTests",
            dependencies: [
                "CaseProjection",
                "MacroPlugin",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            path: "Tests",
            swiftSettings: .upcomingFeatures
        )
    ]
)

extension Array where Element == SwiftSetting {

    static var upcomingFeatures: [SwiftSetting] {
        [
            .enableUpcomingFeature("ExistentialAny"),
            .swiftLanguageMode(.v6)
        ]
    }
}
