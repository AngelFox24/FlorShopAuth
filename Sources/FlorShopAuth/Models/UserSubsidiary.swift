import Vapor
import Fluent

enum UserSubsidiaryRole: String, Codable {
    case cashier, manager, employee, saler
}

enum SubsidiaryUserStatus: String, Codable {
    case active, pending, inactive
}

final class UserSubsidiary: Model, Content, @unchecked Sendable {
    static let schema = "user_subsidiary"

    @ID var id: UUID?

    @Parent(key: "user_id") var user: User
    @Parent(key: "subsidiary_id") var subsidiary: Subsidiary

    @Field(key: "role") var role: UserSubsidiaryRole
    @Field(key: "status") var status: SubsidiaryUserStatus

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(
        userId: UUID,
        subsidiaryId: UUID,
        role: UserSubsidiaryRole,
        status: SubsidiaryUserStatus
    ) {
        self.$user.id = userId
        self.$subsidiary.id = subsidiaryId
        self.role = role
        self.status = status
    }
}

extension UserSubsidiary {
//    static func findOwnerUserCompany(
//        provider: AuthProvider,
//        providerID: String,
//        subdomain: String,
//        on db: any Database
//    ) async throws -> UserSubsidiary? {
//        try await UserSubsidiary.query(on: db)
//            .join(User.self, on: \UserSubsidiary.$user.$id == \User.$id)
//            .join(UserIdentity.self, on: \UserSubsidiary.$user.$id == \UserIdentity.$user.$id)
//            .join(Company.self, on: \UserSubsidiary.$subsidiary.$id == \Company.$id)
//            .filter(UserIdentity.self, \.$provider == provider)
//            .filter(UserIdentity.self, \.$providerID == providerID)
//            .filter(\.$role == .owner)
//            .filter(Company.self, \.$subdomain == subdomain)
//            .with(\.$user)
//            .with(\.$subsidiary)
//            .first()
//    }
    static func findCompanies(for userId: UUID, on db: any Database) async throws -> [Company] {
        let subsidiaries = try await UserSubsidiary.query(on: db)
            .filter(\.$user.$id == userId)
            .with(\.$subsidiary) { $0.with(\.$company) }
            .all()
        
        let companies = subsidiaries.compactMap { $0.subsidiary.company }
        let uniqueCompanies = Dictionary(grouping: companies, by: \.id).compactMap { $0.value.first }
        
        return uniqueCompanies
    }
    static func findSubsidiaries(
        provider: AuthProvider,
        providerID: String,
        on db: any Database
    ) async throws -> [UserSubsidiary] {
        try await UserSubsidiary.query(on: db)
            .join(User.self, on: \UserSubsidiary.$user.$id == \User.$id)
            .join(UserIdentity.self, on: \UserSubsidiary.$user.$id == \UserIdentity.$user.$id)
            .join(Company.self, on: \UserSubsidiary.$subsidiary.$id == \Company.$id)
            .filter(UserIdentity.self, \.$provider == provider)
            .filter(UserIdentity.self, \.$providerID == providerID)
            .with(\.$user)
            .with(\.$subsidiary)
            .all()
    }
    static func validateUserWorksAtSubsidiary(
        userId: UUID,
        subsidiaryId: UUID,
        on db: any Database
    ) async throws {
        guard try await UserSubsidiary
            .query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$subsidiary.$id == subsidiaryId)
            .first() != nil else {
            throw Abort(.badRequest, reason: "User don't work at this company")
        }
    }
}
