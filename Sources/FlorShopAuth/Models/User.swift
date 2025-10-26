import Vapor
import Fluent

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID var id: UUID?

    @Field(key: "user_cic") var userCic: String
    
    @Children(for: \.$user) var identities: [UserIdentity]
    @Children(for: \.$user) var subsidiaries: [UserSubsidiary]

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(userCic: String) {
        self.userCic = userCic
    }
}

extension User {
    func listWorkCompanies(on db: any Database) async throws -> [Company] {
        guard let id else {
            return []
        }
        return try await Company.query(on: db)
            .join(Subsidiary.self, on: \Subsidiary.$company.$id == \Company.$id)
            .join(UserSubsidiary.self, on: \UserSubsidiary.$subsidiary.$id == \Subsidiary.$id)
            .join(User.self, on: \User.$id == \UserSubsidiary.$user.$id)
            .filter(User.self, \.$id == id)
            .all()
    }
}

extension User {
    static func findUser(userCic: String, on db: any Database) async throws -> User? {
        try await User.query(on: db)
            .filter(\.$userCic == userCic)
            .first()
    }
    static func findUser(email: String, provider: AuthProvider, on db: any Database) async throws -> User? {
        try await User.query(on: db)
            .join(UserIdentity.self, on: \User.$id == \UserIdentity.$user.$id)
            .filter(UserIdentity.self, \.$provider == provider)
            .filter(UserIdentity.self, \.$email == email)
            .first()
    }
}
