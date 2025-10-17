import Fluent
import Vapor

struct AuthController: RouteCollection {
    let authProviderManager: AuthProviderManager
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post(use: authHandler)
    }

    //Endpoint: auth/google?origin=pizzarely
    //Focus in register a new client with a premium pass
    @Sendable
    func authHandler(_ req: Request) async throws -> BaseTokenResponse {
        let authRequest = try req.content.decode(AuthRequest.self)
        let userIdentityDTO = try await authProviderManager.verifyToken(authRequest.token, using: authRequest.provider, on: req)
        guard let userIdentity = try await asociateUser(provider: authRequest.provider, userIdentityDTO: userIdentityDTO, on: req.db) else {//asocia si existe
            throw Abort(.unauthorized, reason: "UserIdentity not found")
        }
        let user = try await userIdentity.$user.get(on: req.db)
        let tokenString = try await TokenService.generateBaseToken(for: user, req: req)
        return BaseTokenResponse(baseToken: tokenString)
    }
    private func asociateUser(provider: AuthProvider, userIdentityDTO: UserIdentityDTO, on db: any Database) async throws -> UserIdentity? {
        let userIdentities = try await UserIdentity.findUserIdentity(email: userIdentityDTO.email, on: db)
        if let userId = userIdentities.first?.user.id {//Existe usuario con este email
            if !userIdentities.contains(where: { $0.provider == provider}) {//No existe el proveedor entonces asociamos
                let newUserIdentity = UserIdentity(
                    userID: userId,
                    provider: provider,
                    providerID: userIdentityDTO.id,
                    email: userIdentityDTO.email
                )
                try await newUserIdentity.save(on: db)
                return newUserIdentity
            }
        }
        return nil
    }
}
