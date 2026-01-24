// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "FietsUp_back",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐬 Fluent driver for MySQL.
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.4.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // Token generation for user authentication
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        // Rate limit requests
        .package(url: "https://github.com/nodes-vapor/gatekeeper.git", from: "4.0.0"),
        // Generate OpenApi (swagger) documentation
        .package(url: "https://github.com/dankinsoid/VaporToOpenAPI.git", from: "4.8.1"),
    ],
    targets: [
        .executableTarget(
            name: "FietsUp_back",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "Gatekeeper", package: "gatekeeper"),
                .product(name: "VaporToOpenAPI", package: "VaporToOpenAPI"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FietsUp_backTests",
            dependencies: [
                .target(name: "FietsUp_back"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
