import Fluent
import Vapor

struct AuthController: RouteCollection {
    let authProviderManager: AuthProviderManager
    let userManipulation: UserManipulation
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        let refresh = auth.grouped("refresh")
        auth.post(use: authHandler)
        refresh.post(use: refreshScopedToken)
    }
    //Post: auth
    @Sendable
    func authHandler(_ req: Request) async throws -> BaseTokenResponse {
        let authRequest = try req.content.decode(AuthRequest.self)
        let userIdentityDTO: UserIdentityDTO = try await authProviderManager.verifyToken(authRequest.token, using: authRequest.provider, on: req)
        try await userManipulation.asociateInvitationIfExist(provider: authRequest.provider, userIdentityDTO: userIdentityDTO, on: req.db)
        guard let user = try await userManipulation.asociateUser(//asocia si existe
            provider: authRequest.provider,
            userIdentityDTO: userIdentityDTO,
            on: req.db
        ) else {
            throw Abort(.unauthorized, reason: "UserIdentity not found")
        }
        let tokenString = try await TokenService.generateBaseToken(for: user, req: req)
        return BaseTokenResponse(baseToken: tokenString)
    }
    //Post: auth/refresh
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
            userSubsidiary: refreshToken.userSubsidiary,
            req: req
        )
        return ScopedTokenResponse(scopedToken: scopedToken)
    }
}
