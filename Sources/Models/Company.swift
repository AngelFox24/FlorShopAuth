import Vapor
import Fluent

final class Company: Model, @unchecked Sendable {
    static let schema = "companies"

    @ID var id: UUID?

    @Parent(key: "user_id") var user: User
    
    @Field(key: "company_cic") var companyCic: String
    @Field(key: "name") var name: String

    @Children(for: \.$company) var subsidiaries: [Subsidiary]

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(
        userId: UUID,
        companyCic: String,
        name: String
    ) {
        self.$user.id = userId
        self.companyCic = companyCic
        self.name = name
    }
}

extension Company {
    func getOwner(on db: any Database) async throws -> User {
        return try await $user.get(on: db)
    }
}

extension Company {
    static func findCompany(companyCic: String, on db: any Database) async throws -> Company? {
        try await Company.query(on: db)
            .filter(Company.self, \.$companyCic == companyCic)
            .first()
    }
    static func companyNameExist(name: String, on db: any Database) async throws -> Bool {
        if let _ = try await Company.query(on: db)
            .filter(Company.self, \.$name == name)
            .first() {
            return true
        } else {
            return false
        }
    }
    static func validateCompanyNotExist(name: String, on db: any Database) async throws {
        // Verificar si existe una compañía con el mismo nombre o subdominio
        let existingCompany = try await Company.query(on: db)
            .group(.or) { group in
                group.filter(\.$name == name)
            }
            .first()
        
        if let company = existingCompany {
            if company.name == name {
                throw Abort(.conflict, reason: "A company with the name '\(name)' already exists.")
            }
        }
    }
    static func listUserWorkCompanies(userCic: String, on db: any Database) async throws -> [Company] {
        try await Company.query(on: db)
            .join(Subsidiary.self, on: \Subsidiary.$company.$id == \Company.$id)
            .join(UserSubsidiary.self, on: \UserSubsidiary.$subsidiary.$id == \Subsidiary.$id)
            .join(User.self, on: \User.$id == \UserSubsidiary.$user.$id)
            .filter(User.self, \.$userCic == userCic)
            .filter(UserSubsidiary.self, \.$status == .active)
            .with(\.$user)
//            .with(\.$subsidiaries) { subsidiary in
//                subsidiary.with(\.$userSubsidiaries)
//            }
            .all()
    }
    static func listUserInvitedCompanies(userCic: String, on db: any Database) async throws -> [Company] {
        try await Company.query(on: db)
            .join(Subsidiary.self, on: \Subsidiary.$company.$id == \Company.$id)
            .join(Invitation.self, on: \Invitation.$subsidiary.$id == \Subsidiary.$id)
            .join(User.self, on: \User.$id == \Invitation.$invitedUser.$id)
            .filter(User.self, \.$userCic == userCic)
            .filter(Invitation.self, \.$status == .pending)
            .filter(Invitation.self, \.$expiredAt >= Date())
            .with(\.$user)
//            .with(\.$subsidiaries) { subsidiary in
//                subsidiary.with(\.$invitations) { invitation in
//                    invitation.with(\.$invitedUser)
//                }
//            }
            .all()
    }
}
