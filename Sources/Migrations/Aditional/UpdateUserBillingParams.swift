import Fluent

struct UpdateUserBillingParams: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .field("first_name", .string)
            .field("last_name", .string)
            .field("phone_number", .string)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(User.schema)
            .deleteField("first_name")
            .deleteField("last_name")
            .deleteField("phone_number")
            .update()
    }
}
