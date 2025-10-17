import Fluent

struct CreateSubsidiary: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Subsidiary.schema)
            .id()
            .field("company_id", .uuid, .required, .references(Company.schema, "id", onDelete: .cascade))
            .field("subsidiary_cic", .string, .required)
            .field("name", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "subsidiary_cic")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Subsidiary.schema).delete()
    }
}
