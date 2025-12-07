import Vapor

enum EnvironmentVariables: String {
    case logLevel = "LOG_LEVEL"
    case httpServerHost = "HTTP_SERVER_HOST"
    case httpServerPort = "HTTP_SERVER_PORT"
    case dataBaseHost = "DATABASE_HOST"
    case dataBaseName = "DATABASE_NAME"
    case dataBasePort = "DATABASE_PORT"
    case dataBaseUserName = "DATABASE_USERNAME"
    case dataBasePassword = "DATABASE_PASSWORD"
    case googleClientId = "GOOGLE_CLIENT_ID"
    case pgData = "PGDATA"
    case postgresUser = "POSTGRES_USER"
    case postgresPassword = "POSTGRES_PASSWORD"
    case postgresDB = "POSTGRES_DB"
    case jwtHmacInternalKey = "JWT_HMAC_INTERNAL_KEY"
    case jwtEcdsaExternalPrivateKeyPath = "JWT_ECDSA_EXTERNAL_PRIVATE_KEY_PATH"
    case jwtEcdsaExternalPublicKeyPath = "JWT_ECDSA_EXTERNAL_PUBLIC_KEY_PATH"
}

extension EnvironmentVariables: CaseIterable {
    static func validate(envName: String) throws {
        let allCases = Self.allCases
        for envVar in allCases {
            guard let _ = Environment.get(envVar.rawValue) else {
                throw Abort(.internalServerError, reason: "\(envVar.rawValue) don't found in .env.\(envName)")
            }
        }
    }
}
