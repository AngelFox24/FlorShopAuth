import Vapor
import Fluent

enum AuthProvider: String, Codable {
    case google, facebook, apple
}

final class UserIdentity: Model, @unchecked Sendable {
    static let schema = "user_identities"

    @ID var id: UUID?

    @Parent(key: "user_id") var user: User

    @Field(key: "provider") var provider: AuthProvider
    @Field(key: "provider_id") var providerID: String
    @Field(key: "email") var email: String

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(
        userID: UUID,
        provider: AuthProvider,
        providerID: String,
        email: String
    ) {
        self.$user.id = userID
        self.provider = provider
        self.providerID = providerID
        self.email = email
    }
}

extension UserIdentity {
    static func findUserIdentity(email: String, on db: any Database) async throws -> [UserIdentity] {
        try await UserIdentity.query(on: db)
            .filter(UserIdentity.self, \.$email == email)
            .with(\.$user)
            .all()
    }
    static func findUserIdentity(email: String, provider: AuthProvider, on db: any Database) async throws -> UserIdentity? {
        try await UserIdentity.query(on: db)
            .filter(UserIdentity.self, \.$email == email)
            .filter(UserIdentity.self, \.$provider == provider)
            .with(\.$user)
            .first()
    }
}
