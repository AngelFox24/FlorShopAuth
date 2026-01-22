import Foundation
import Vapor
import Fluent
import JWT
import FlorShopDTOs

struct TokenService {
    static func generateBaseToken(for user: User, req: Request) async throws -> String {
        let now = Date()
        let exp = now.addingTimeInterval(3600) // 1 hora
        let payload = BaseTokenPayload(
            subject: user.userCic,
            issuedAt: now,
            expiration: exp
        )
        let token = try await req.jwt.sign(payload, kid: JWTKeyID.externalService.kid)
        return token
    }
    static func generateScopedToken(userSubsidiary: UserSubsidiary, req: Request) async throws -> String {
        let now = Date()
        let exp = now.addingTimeInterval(3600) // 1 hora
        let user = try await userSubsidiary.$user.get(on: req.db)
        let subsidiary = try await userSubsidiary.$subsidiary.get(on: req.db)
        let company = try await subsidiary.$company.get(on: req.db)
        let owner = try await company.$user.get(on: req.db)
        let payload = ScopedTokenPayload(
            subject: user.userCic,
            companyCic: company.companyCic,
            subsidiaryCic: subsidiary.subsidiaryCic,
            isOwner: owner.userCic == user.userCic,
            issuedAt: now,
            expiration: exp
        )
        let token = try await req.jwt.sign(payload, kid: JWTKeyID.externalService.kid)
        return token
    }
    private static func getSubdomain(for userSubsidiary: UserSubsidiary, req: Request) async throws -> String {
        try await userSubsidiary.$subsidiary.load(on: req.db)
        let subsidiary = userSubsidiary.subsidiary
        try await subsidiary.$company.load(on: req.db)
        let company = subsidiary.company
        return company.subdomain
    }
    static func getRefreshScopedToken(userSubsidiary: UserSubsidiary, req: Request) async throws -> String {
        let subsidiary = try await userSubsidiary.$subsidiary.get(on: req.db)
        let user = try await userSubsidiary.$user.get(on: req.db)
        guard let userSubsidiaryId = userSubsidiary.id,
              let userId = user.id,
              let subsidiaryId = subsidiary.id else {
            throw Abort(.internalServerError, reason: "UserId or CompanyId not found for refresh token")
        }
        let refreshToken: RefreshToken
        if let refreshTokenFound = try await RefreshToken.getRefreshScopedToken(userId: userId, subsidiaryId: subsidiaryId, on: req.db)  {
            if !refreshTokenFound.isValid() {
                let newRefreshToken = try await TokenService.generateRefreshToken(userSubsidiaryId: userSubsidiaryId, req: req)
                refreshToken = newRefreshToken
            } else {
                refreshToken = refreshTokenFound
            }
        } else {
            let newRefreshToken = try await TokenService.generateRefreshToken(userSubsidiaryId: userSubsidiaryId, req: req)
            refreshToken = newRefreshToken
        }
        try refreshToken.validate()
        return refreshToken.token
    }
    static func generateRefreshToken(userSubsidiaryId: UUID, req: Request) async throws -> RefreshToken {
        let randomBytes = [UInt8].random(count: 32)
        let token = Data(randomBytes).base64EncodedString()
        let expiresAt = Date().addingTimeInterval(60 * 60 * 24 * 30)// 30 días
        let newRefresToken = RefreshToken(
            userSubsidiaryId: userSubsidiaryId,
            token: token,
            expiresAt: expiresAt,
            revoked: false
        )
        try await newRefresToken.save(on: req.db)
        return newRefresToken
    }
}
