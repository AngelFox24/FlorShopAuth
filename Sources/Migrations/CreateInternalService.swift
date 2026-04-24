import Fluent

struct CreateInternalService: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(InternalService.schema)
            .id()
            .field("service_name", .string, .required)
            .field("secret_hash", .string, .required)
            .field("is_active", .bool, .required, .sql(.default(true)))
            .field("scopes", .array(of: .string), .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "service_name")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(InternalService.schema).delete()
    }
}
