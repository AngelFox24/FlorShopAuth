import Fluent

struct CreateCompany: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Company.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("company_cic", .string, .required)
            .field("name", .string, .required)
            .field("subdomain", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "subdomain")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Company.schema).delete()
    }
}
