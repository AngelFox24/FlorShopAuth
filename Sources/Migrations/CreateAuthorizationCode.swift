import Fluent

struct CreateAuthorizationCode: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(AuthorizationCode.schema)
            .id()
            .field("code", .string, .required)
            .field("base_token", .string, .required)
            .field("expired_at", .datetime, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "code")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(AuthorizationCode.schema).delete()
    }
}
