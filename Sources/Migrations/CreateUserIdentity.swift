import Fluent

struct CreateUserIdentity: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserIdentity.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .field("provider", .string, .required)
            .field("provider_id", .string, .required)
            .field("email", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "provider", "provider_id") // 🔐 Unicidad compuesta
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(UserIdentity.schema).delete()
    }
}
