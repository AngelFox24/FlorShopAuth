import Vapor
import JWT
import FlorShopDTOs

struct AuthController: RouteCollection {
    let authProviderManager: AuthProviderManager
    let userManipulation: UserManipulation
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.get(use: getKeys)
        auth.post(use: authHandler)
        let refresh = auth.grouped("refresh")
        refresh.post(use: refreshScopedToken)
    }
    //Get: auth
    func getKeys(req: Request) throws -> Response {
        guard let publicKeyPath = Environment.get(EnvironmentVariables.jwtEcdsaExternalPublicKeyPath.rawValue) else {//Se obtiene en el momento porque se espera que un futuro rote las claves
            throw Abort(.internalServerError, reason: "Public key \(EnvironmentVariables.jwtEcdsaExternalPublicKeyPath.rawValue) not found in .env.***")
        }

        let publicKey = try ES256PublicKey(pem: String(contentsOfFile: publicKeyPath))
        guard let parameters = publicKey.parameters else {
            throw Abort(.internalServerError, reason: "Public don't have parameters")
        }
        let jwkJSON = """
        {
            "keys": [
                {
                    "kty": "EC",
                    "use": "sig",
                    "alg": "ES256",
                    "kid": "external-key",
                    "crv": "P-256",
                    "x": "\(parameters.x)",
                    "y": "\(parameters.y)"
                }
            ]
        }
        """
        let response = Response()
        response.headers.add(name: .contentType, value: "application/json")
        // 1️⃣ Cache-Control: permite que los clientes almacenen la respuesta en cache
        // max-age = 24 hora (86400 s) como ejemplo
        response.headers.add(name: .cacheControl, value: "public, max-age=86400")
        
        // 2️⃣ ETag: permite validación condicional con If-None-Match
        let etag = "\"\(jwkJSON.hashValue)\""
        response.headers.add(name: .eTag, value: etag)
        
        // 3️⃣ Comprobación de If-None-Match para responder 304 Not Modified
        if let ifNoneMatch = req.headers.first(name: .ifNoneMatch), ifNoneMatch == etag {
            response.status = .notModified
            response.body = .empty
            return response
        }
        response.body = .init(string: jwkJSON)
        return response
    }
    //Post: auth
    @Sendable
    func authHandler(_ req: Request) async throws -> BaseTokenResponse {
        let authRequest = try req.content.decode(AuthRequest.self)
        let userIdentityDTO: UserIdentityDTO = try await authProviderManager.verifyToken(using: authRequest.provider, on: req)
        try await userManipulation.asociateInvitationIfExist(provider: authRequest.provider, userIdentityDTO: userIdentityDTO, on: req.db)
        let _ = try await userManipulation.asociateUser(//asocia si existe
            provider: authRequest.provider,
            userIdentityDTO: userIdentityDTO,
            on: req.db
        )
        guard let user = try await User.findUser(
            email: userIdentityDTO.email,
            provider: authRequest.provider,
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
        guard let refreshToken = try await RefreshToken.findRefreshScopedToken(token: refreshTokenDTO.refreshToken, on: req.db) else {
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
