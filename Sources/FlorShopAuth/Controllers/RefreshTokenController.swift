import Fluent
import Vapor

struct RefreshTokenController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        let refresh = auth.grouped("refresh")
        refresh.post(use: refreshScopedToken)
    }
    
    struct TestResponse: Content {
        let result: String
    }
    @Sendable
    func refreshScopedToken(req: Request) async throws -> ScopedTokenResponse {
        guard let refreshTokenDTO = try? req.content.decode(RefreshTokenRequest.self) else {
            throw Abort(.badRequest, reason: "Invalid request, need a refresh token")
        }
        guard let refreshToken = try await RefreshToken.findRefreshScopedToken(token: refreshTokenDTO.refreshScopedToken, on: req.db) else {
            throw Abort(.unauthorized, reason: "Invalid refresh token")
        }
        try refreshToken.validate()
        let scopedToken = try await TokenService.generateScopedToken(
            for: refreshToken.userSubsidiary.user,
            subsidiary: refreshToken.userSubsidiary.subsidiary,
            req: req
        )
        return ScopedTokenResponse(scopedToken: scopedToken)
    }
}
