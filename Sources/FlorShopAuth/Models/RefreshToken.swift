import Vapor
import Fluent

final class RefreshToken: Model, @unchecked Sendable {
    static let schema = "refresh_tokens"

    @ID var id: UUID?
    
    @Parent(key: "user_subsidiary_id") var userSubsidiary: UserSubsidiary

    @Field(key: "token") var token: String
    @Field(key: "expires_at") var expiresAt: Date
    @Field(key: "revoked") var revoked: Bool

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(
        userSubsidiaryId: UUID,
        token: String,
        expiresAt: Date,
        revoked: Bool
    ) {
        self.$userSubsidiary.id = userSubsidiaryId
        self.token = token
        self.expiresAt = expiresAt
        self.revoked = revoked
    }
}

extension RefreshToken {
    static func getRefreshScopedToken(userId: UUID, subsidiaryId: UUID, on db: any Database) async throws -> RefreshToken? {
        try await RefreshToken.query(on: db)
            .join(UserSubsidiary.self, on: \RefreshToken.$userSubsidiary.$id == \UserSubsidiary.$id)
            .join(User.self, on: \UserSubsidiary.$user.$id == \User.$id)
            .join(Subsidiary.self, on: \UserSubsidiary.$subsidiary.$id == \Subsidiary.$id)
            .filter(User.self, \.$id == userId)
            .filter(Subsidiary.self, \.$id == subsidiaryId)
            .first()
    }
    static func findRefreshScopedToken(token: String, on db: any Database) async throws -> RefreshToken? {
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Refresh token is required.")
        }
        return try await RefreshToken.query(on: db)
            .join(UserSubsidiary.self, on: \RefreshToken.$userSubsidiary.$id == \UserSubsidiary.$id)
            .filter(RefreshToken.self, \.$token == token)
            .filter(UserSubsidiary.self, \.$status == .active) // 👈 solo user_companies activos
            .with(\.$userSubsidiary)
            .first()
    }
}

extension RefreshToken {
    func validate() throws {
        guard !revoked else {
            throw Abort(.forbidden, reason: "Refresh token has been revoked.")
        }
        guard expiresAt > Date() else {
            throw Abort(.forbidden, reason: "Refresh token has expired.")
        }
    }
}
