import Vapor
import Fluent

final class Company: Model, @unchecked Sendable {
    static let schema = "companies"

    @ID var id: UUID?

    @Parent(key: "user_id") var user: User
    
    @Field(key: "company_cic") var companyCic: String
    @Field(key: "name") var name: String
    @Field(key: "subdomain") var subdomain: String

    @Children(for: \.$company) var subsidiaries: [Subsidiary]

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(
        userId: UUID,
        companyCic: String,
        name: String,
        subdomain: String
    ) {
        self.$user.id = userId
        self.companyCic = companyCic
        self.name = name
        self.subdomain = subdomain
    }
}

extension Company {
    func getOwner(on db: any Database) async throws -> User {
        return try await $user.get(on: db)
    }
}

extension Company {
    static func findCompany(subdomain: String, on db: any Database) async throws -> Company? {
        try await Company.query(on: db)
            .filter(Company.self, \.$subdomain == subdomain)
            .first()
    }
    static func companyExist(subdomain: String, on db: any Database) async throws -> Bool {
        if let _ = try await Company.query(on: db)
            .filter(Company.self, \.$subdomain == subdomain)
            .first() {
            return true
        } else {
            return false
        }
    }
}
