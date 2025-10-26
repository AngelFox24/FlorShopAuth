import Vapor
import Fluent

final class Subsidiary: Model, @unchecked Sendable {
    static let schema = "subsidiaries"

    @ID var id: UUID?
    
    @Parent(key: "company_id") var company: Company

    @Field(key: "subsidiary_cic") var subsidiaryCic: String
    @Field(key: "name") var name: String
    
    @Children(for: \.$subsidiary) var userSubsidiaries: [UserSubsidiary]
    @Children(for: \.$subsidiary) var invitations: [Invitation]

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(
        companyId: UUID,
        subsidiaryCic: String,
        name: String
    ) {
        self.$company.id = companyId
        self.subsidiaryCic = subsidiaryCic
        self.name = name
    }
}

extension Subsidiary {
    func getCompanyOwner(on db: any Database) async throws -> User {
        let company = try await self.$company.get(on: db)
        return try await company.$user.get(on: db)
    }
}

extension Subsidiary {
    static func findSubsidiary(subsidiaryCic: String, on db: any Database) async throws -> Subsidiary? {
        try await Subsidiary.query(on: db)
            .filter(\.$subsidiaryCic == subsidiaryCic)
            .first()
    }
    static func findSubsidiary(subsidiaryId: UUID, on db: any Database) async throws -> Subsidiary? {
        try await Subsidiary.find(subsidiaryId, on: db)
    }
//    static func companyExist(subdomain: String, on db: any Database) async throws -> Bool {
//        if let _ = try await Company.query(on: db)
//            .filter(Company.self, \.$subdomain == subdomain)
//            .first() {
//            return true
//        } else {
//            return false
//        }
//    }
//    static func findUser(subdomain: String, on db: any Database) async throws -> Company? {
//        try await Company.query(on: db)
//            .filter(Company.self, \.$subdomain == subdomain)
//            .first()
//    }
}
