import Vapor
import JWT
import FlorShopDTOs

struct AuthController: RouteCollection {
    let authProviderManager: AuthProviderManager
    let userManipulation: UserManipulation
    let florShopWebRedirection: String = AppConfig.florShopWebBaseURL + "/auth/complete"
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.get(use: getKeys)
        auth.post(use: authHandler)
        let refresh = auth.grouped("refresh")
        refresh.post(use: refreshScopedToken)
        let google = auth.grouped("google")
        google.get(use: googleLogin)
        let exchange = auth.grouped("exchange")
        exchange.post(use: exchangeAuthCodeForToken)
        let googleCallbakc = google.grouped("callback")
        googleCallbakc.get(use: googleCallback)
    }
    //MARK: Get: auth
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
    //MARK: Post: auth
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
    //MARK: Post: auth/refresh
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
    //MARK: GET: auth/google
    @Sendable
    func googleLogin(req: Request) throws -> Response {
        guard let clientID = Environment.get(EnvironmentVariables.googleClientId.rawValue),
              let redirectURI = Environment.get(EnvironmentVariables.googleRedirectUri.rawValue)
        else {
            throw Abort(.internalServerError)
        }
        let scope = "openid email profile"
        let googleURL =
        "https://accounts.google.com/o/oauth2/v2/auth" +
        "?client_id=\(clientID)" +
        "&redirect_uri=\(redirectURI)" +
        "&response_type=code" +
        "&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        return req.redirect(to: googleURL)
    }
    //MARK: GET: auth/google/callback
    @Sendable
    func googleCallback(req: Request) async throws -> Response {
        let code = try req.query.get(String.self, at: "code")
        // Intercambiar code por token de Google
        let googleToken = try await exchangeCodeForToken(code: code, req: req)
        // Buscar/crear usuario y generar baseToken
        let userIdentityDTO: UserIdentityDTO = try await authProviderManager.verifyToken(token: googleToken.id_token, using: .google, on: req)
        try await userManipulation.asociateInvitationIfExist(provider: .google, userIdentityDTO: userIdentityDTO, on: req.db)
        let _ = try await userManipulation.asociateUser(//asocia si existe
            provider: .google,
            userIdentityDTO: userIdentityDTO,
            on: req.db
        )
        guard let user = try await User.findUser(
            email: userIdentityDTO.email,
            provider: .google,
            on: req.db
        ) else {
            throw Abort(.unauthorized, reason: "UserIdentity not found")
        }
        let tokenString = try await TokenService.generateBaseToken(for: user, req: req)
        let newAuthCode = AuthorizationCode(
            code: Data((0..<32).map { _ in UInt8.random(in: 0...255) }).base64EncodedString(),
            baseToken: tokenString,
            expiredAt: Date().addingTimeInterval(60)
        )
        try await newAuthCode.save(on: req.db)
        let redirectionWithCode = "\(florShopWebRedirection)?code=\(newAuthCode.code)"
        let redirect = URI(string: redirectionWithCode)
        let response = req.redirect(to: redirect.string)
        response.headers.cacheControl = .init(noStore: true)
        response.headers.add(name: .pragma, value: "no-cache")
        return response
    }
    //MARK: POST: auth/exchange
    @Sendable
    func exchangeAuthCodeForToken(req: Request) async throws -> BaseTokenResponse {
        let codeExchangeReq = try req.content.decode(CodeExchangeRequest.self)
        let baseToken = try await AuthorizationCode.use(code: codeExchangeReq.code, on: req.db)
        return BaseTokenResponse(baseToken: baseToken)
    }
    private func exchangeCodeForToken(code: String, req: Request) async throws -> GoogleToken {
        guard
            let clientID = Environment.get(EnvironmentVariables.googleClientId.rawValue),
            let clientSecret = Environment.get(EnvironmentVariables.googleClientSecret.rawValue),
            let redirectURI = Environment.get(EnvironmentVariables.googleRedirectUri.rawValue)
        else {
            throw Abort(.internalServerError, reason: "Missing env vars")
        }

        let tokenRes = try await req.client.post(URI(string: "https://oauth2.googleapis.com/token")) { tokenReq in
            try tokenReq.content.encode([
                "code": code,
                "client_id": clientID,
                "client_secret": clientSecret,
                "redirect_uri": redirectURI,
                "grant_type": "authorization_code"
            ])
        }
        return try tokenRes.content.decode(GoogleToken.self)
    }
}
struct GoogleToken: Content {
    let access_token: String
    let id_token: String
    let expires_in: Int?
}
