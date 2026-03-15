import Fluent

struct CreateUserSubsidiary: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserSubsidiary.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("subsidiary_id", .uuid, .required, .references(Subsidiary.schema, "id", onDelete: .cascade))
            .field("role", .string, .required) // Enum: owner, manager, employee
            .field("status", .string, .required) // Enum: active, pending, inactive
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id", "subsidiary_id") // para evitar duplicaciones
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(UserSubsidiary.schema).delete()
    }
}
