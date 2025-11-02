import FluentPostgresDriver
import Vapor

extension Application {
    func getFactory() throws -> DatabaseConfigurationFactory {
        switch self.environment {
        case .production:
            return .postgres(configuration: .init(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
                password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
                database: Environment.get("DATABASE_NAME") ?? "FlorAuthDB",
                tls: .prefer(try .init(configuration: .clientDefault))
            ))
        default://develop
            return .postgres(
                configuration: .init(
                    hostname: "192.168.2.7",
                    port: 5433,
                    username: "vapor_username",
                    password: "vapor_password",
                    database: "FlorAuthDB",
                    tls: .disable)
            )
        }
    }
    func getDatabaseID() -> DatabaseID {
        switch self.environment {
        default:
            return .psql
        }
    }
    func configLogger() {
        if let logLevelString = Environment.get("LOG_LEVEL"),
           let level = Logger.Level(rawValue: logLevelString.lowercased()) {
            self.logger.logLevel = level
        } else {
            self.logger.logLevel = self.environment == .development ? .debug : .info
        }
    }
}
