import Fluent

struct CreateRefreshToken: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(RefreshToken.schema)
            .id()
            .field("user_subsidiary_id", .uuid, .required, .references(UserSubsidiary.schema, "id", onDelete: .cascade))
            .field("token", .string, .required)
            .field("expires_at", .datetime, .required)
            .field("revoked", .bool, .required, .sql(.default(false)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "token")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(RefreshToken.schema).delete()
    }
}
