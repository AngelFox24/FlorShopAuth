// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "FlorShopAuth",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🔵 Para generar tokens
        .package(url: "https://github.com/vapor/jwt.git", exact: "5.1.2"),
        // 🔵 Extension para validar FlorShopAuth
        .package(url: "https://github.com/AngelFox24/florshop-auth-client.git", exact: "0.0.6"),
        // 🔵 Extension para Networking
        .package(url: "https://github.com/AngelFox24/florshop-networking.git", exact: "0.0.5"),
        // 🔵 Shared DTOs
//        .package(url: "https://github.com/AngelFox24/florshop-dtos.git", exact: "1.0.27")
        //        .package(path: "../florshop-dtos")
            .package(url: "https://github.com/AngelFox24/florshop-dtos.git", branch: "feature/add-create-culqi-orders")
    ],
    targets: [
        .executableTarget(
            name: "FlorShopAuth",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "FlorShopDTOs", package: "florshop-dtos"),
                .product(name: "FlorShopAuthClient", package: "florshop-auth-client"),
                .product(name: "FlorShopNetworking", package: "florshop-networking")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FlorShopAuthTests",
            dependencies: [
                .target(name: "FlorShopAuth"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
