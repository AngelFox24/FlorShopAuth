import Fluent

struct CreateInvitation: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Invitation.schema)
            .id()
            .field("invited_by_user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("subsidiary_id", .uuid, .required, .references(Subsidiary.schema, "id", onDelete: .cascade))
            .field("invited_user_id", .uuid, .references(User.schema, "id", onDelete: .cascade))
            .field("email", .string, .required)
            .field("role", .string, .required)
            .field("status", .string, .required)
            .field("expired_at", .datetime, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email", "subsidiary_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Company.schema).delete()
    }
}
