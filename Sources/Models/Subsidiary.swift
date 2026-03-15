import Vapor
import Fluent
import FlorShopDTOs

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
    static func subsidiaryNameExist(name: String, on db: any Database) async throws -> Bool {
        if let _ = try await Subsidiary.query(on: db)
            .filter(Subsidiary.self, \.$name == name)
            .first() {
            return true
        } else {
            return false
        }
    }
    static func subsidiaryExist(name: String, companyId: UUID, on db: any Database) async throws -> Bool {
        if let _ = try await Subsidiary.query(on: db)
            .join(Company.self, on: \Company.$id == \Subsidiary.$company.$id)
            .filter(Company.self, \.$id == companyId)
            .filter(Subsidiary.self, \.$name == name)
            .first() {
            return true
        } else {
            return false
        }
    }
    static func listUserWorkSubsidiaries(userCic: String, companyCic: String, on db: any Database) async throws -> [Subsidiary] {
        try await Subsidiary.query(on: db)
            .join(Company.self, on: \Subsidiary.$company.$id == \Company.$id)
            .join(UserSubsidiary.self, on: \UserSubsidiary.$subsidiary.$id == \Subsidiary.$id)
            .join(User.self, on: \User.$id == \UserSubsidiary.$user.$id)
            .filter(Company.self, \.$companyCic == companyCic)
            .filter(User.self, \.$userCic == userCic)
            .filter(UserSubsidiary.self, \.$status == .active)
            .with(\.$userSubsidiaries)
            .all()
    }
    
    static func listUserInvitedSubsidiaries(userCic: String, companyCic: String, on db: any Database) async throws -> [Subsidiary] {
        try await Subsidiary.query(on: db)
            .join(Company.self, on: \Subsidiary.$company.$id == \Company.$id)
            .join(Invitation.self, on: \Invitation.$subsidiary.$id == \Subsidiary.$id)
            .join(User.self, on: \User.$id == \Invitation.$invitedUser.$id)
            .filter(Company.self, \.$companyCic == companyCic)
            .filter(User.self, \.$userCic == userCic)
            .filter(Invitation.self, \.$status == .pending)
            .filter(Invitation.self, \.$expiredAt >= Date())
            .with(\.$userSubsidiaries)
            .all()
    }
}
