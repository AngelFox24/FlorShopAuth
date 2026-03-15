import Vapor
import Fluent

final class AuthorizationCode: Model, @unchecked Sendable {
    static let schema = "authorization_codes"

    @ID var id: UUID?
    
    @Field(key: "code") var code: String
    @Field(key: "base_token") var baseToken: String
    @Field(key: "expired_at") var expiredAt: Date

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(
        code: String,
        baseToken: String,
        expiredAt: Date
    ) {
        self.code = code
        self.baseToken = baseToken
        self.expiredAt = expiredAt
    }
}

extension AuthorizationCode {
    static func use(code: String, on db: any Database) async throws -> String {
        guard let authCode = try await AuthorizationCode.query(on: db)
            .filter(\.$code == code)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Authorization code not found")
        }
        guard authCode.expiredAt > Date() else {
            try await authCode.delete(on: db)
            throw Abort(.unauthorized, reason: "Authorization code expired")
        }
        let baseToken = authCode.baseToken
        try await authCode.delete(on: db)
        return baseToken
    }
}
