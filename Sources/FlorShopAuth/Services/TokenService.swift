import Foundation
import Vapor
import Fluent
import JWT

struct TokenService {
    static func generateBaseToken(for user: User, req: Request) async throws -> String {
        let now = Date()
        let exp = now.addingTimeInterval(3600) // 1 hora
        let payload = BaseTokenPayload(
            subject: user.id!.uuidString,
            issuedAt: now,
            expiration: exp
        )
        let token = try await req.jwt.sign(payload)
        return token
    }
    static func generateScopedToken(for user: User, subsidiary: Subsidiary, req: Request) async throws -> String {
        let now = Date()
        let exp = now.addingTimeInterval(3600) // 1 hora
        let company = try await subsidiary.$company.get(on: req.db)
        let owner = try await company.$user.get(on: req.db)
        let payload = ScopedTokenPayload(
            subject: user.id!.uuidString,
            companyCic: company.id?.uuidString ?? "",
            subsidiaryCic: subsidiary.id?.uuidString ?? "",
            isOwner: owner.id == user.id,
            issuedAt: now,
            expiration: exp
        )
        let token = try await req.jwt.sign(payload)
        return token
    }
    static func getRefreshScopedToken(for user: User, subsidiary: Subsidiary, req: Request) async throws -> String {
        guard let userId = user.id,
              let subsidiaryId = subsidiary.id else {
            throw Abort(.internalServerError, reason: "UserId or CompanyId not found for refresh token")
        }
        guard let refreshToken = try await RefreshToken.getRefreshScopedToken(userId: userId, subsidiaryId: subsidiaryId, on: req.db) else  {
            throw Abort(.internalServerError, reason: "User don't have a valid refresh token for this subsidiary")
        }
        try refreshToken.validate()
        return refreshToken.token
    }
}
