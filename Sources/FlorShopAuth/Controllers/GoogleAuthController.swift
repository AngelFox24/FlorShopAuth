import Fluent
import Vapor

struct GoogleAuthRequest: Content {
    let idToken: String
}

struct GoogleAuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth2")
        let google = auth.grouped("google")
        google.post(use: googleAuthHandler)
//        google.post(use: testRegister)
        google.get("callback", use: handleGoogleCallback)
    }

    //Endpoint: auth/google?origin=pizzarely
    //Focus in register a new client with a premium pass
    @Sendable
    func googleAuthHandler(_ req: Request) async throws -> BaseTokenResponse {
        let payload = try req.content.decode(GoogleAuthRequest.self)
        let googleUser: GoogleUser = try await GoogleTokenVerifier.verify(idToken: payload.idToken, on: req.client)
        guard let userIdentity = try await asociateUser(provider: .google, googleUser: googleUser, on: req.db) else {//asocia si existe
            throw Abort(.unauthorized, reason: "UserIdentity not found")
        }
        let user = try await userIdentity.$user.get(on: req.db)
        let tokenString = try await TokenService.generateBaseToken(for: user, req: req)
        return BaseTokenResponse(baseToken: tokenString)
    }
    @Sendable
    func testRegister(req: Request) async throws -> ListCompanyResponse {
        let googleUser = try req.content.decode(GoogleUser.self)
        let subdomain = try? req.query.get(String.self, at: "origin")
        // 4. Buscar o crear usuario + empresa en BD
        if let subdomain {//register
            try await registerUserCompany(
                provider: .google,
                subdomain: subdomain,
                googleUser: googleUser,
                on: req.db
            )
        }
        guard let userIdentity = try await UserIdentity.findUserIdentity(email: googleUser.email, on: req.db).first else {
            throw Abort(.badRequest, reason: "UserIdentity not found")
        }
        let tokenString = try await TokenService.generateBaseToken(for: userIdentity.user, req: req)
        let companies = try await getUserCompanies(provider: .google, googleUser: googleUser, on: req.db)
        return ListCompanyResponse(baseToken: tokenString, companies: companies)
    }
    //MARK: HandleGoogleCallback
    @Sendable//For create a newCompany with premium pass
    func handleGoogleCallback(req: Request) async throws -> ListCompanyResponse {
        // 1. Extraer parámetros (code + state/subdominio)
        let (code, state) = try extractOAuthParams(from: req)
        // 2. Intercambiar code por access_token
        let token = try await exchangeCodeForToken(code: code, req: req)
        // 3. Obtener datos del usuario desde Google
        let googleUser = try await fetchGoogleUser(token: token.access_token, req: req)
        let response = try await req.db.transaction { transaction -> (userIdentity: UserIdentity, companies: [CompanyResponseDTO]) in
            //state != nil -> register
            //state == nil -> only login
            try await asociateUser(provider: .google, googleUser: googleUser, on: transaction)
            if let state {//register
                try await registerUserCompany(provider: .google, subdomain: state, googleUser: googleUser, on: transaction)
            }
            guard let userIdentity = try await UserIdentity.findUserIdentity(email: googleUser.email, on: transaction).first else {
                throw Abort(.badRequest, reason: "UserIdentity not found")
            }
            let companies = try await getUserCompanies(provider: .google, googleUser: googleUser, on: transaction)
            return (userIdentity, companies)
        }
        let tokenString = try await TokenService.generateBaseToken(for: response.userIdentity.user, req: req)
        return ListCompanyResponse(baseToken: tokenString, companies: response.companies)
    }
    func registerUserCompany(provider: AuthProvider, subdomain: String, googleUser: GoogleUser, on db: any Database) async throws {
        guard try await !Company.companyExist(subdomain: subdomain, on: db) else {
            throw Abort(.badRequest, reason: "Company already exists with this subdomain")
        }
        let user: User
        if let userFound = try await User.findUser(email: googleUser.email, provider: provider, on: db) {
            user = userFound
        } else {
            let userCic = UUID().uuidString
            let newUser = User(
                userCic: userCic
            )
            try await newUser.save(on: db)
            guard let userId = newUser.id else {
                throw Abort(.conflict, reason: "New user dont have id")
            }
            let newUserIdentity = UserIdentity(
                userID: userId,
                provider: provider,
                providerID: googleUser.id,
                email: googleUser.email
            )
            try await newUserIdentity.save(on: db)
            user = newUser
        }
        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "Failed to generate IDs for new user")
        }
        let companyCic = UUID().uuidString
        let newCompany = Company(
            userId: userId,
            companyCic: companyCic,
            name: subdomain,
            subdomain: subdomain
        )
        try await newCompany.save(on: db)
        guard let companyId = newCompany.id else {
            throw Abort(.internalServerError, reason: "Failed to generate IDs for new user or company")
        }
        let subsidiaryCic = UUID().uuidString
        let newSusidiary = Subsidiary(
            companyId: companyId,
            subsidiaryCic: subsidiaryCic,
            name: subdomain+"_subsidiary"
        )
        try await newSusidiary.save(on: db)
        guard let subsidiaryId = newSusidiary.id else {
            throw Abort(.internalServerError, reason: "Failed to generate IDs for new subsidiary")
        }
        let newUserSubsidiary = UserSubsidiary(
            userId: userId,
            subsidiaryId: subsidiaryId,
            role: .employee,
            status: .active
        )
        try await newUserSubsidiary.save(on: db)
        guard let userSubsidiaryId = newUserSubsidiary.id else {
            throw Abort(.internalServerError, reason: "Failed to generate IDs for new userCompany")
        }
        let randomBytes = [UInt8].random(count: 32)
        let refreshToken = Data(randomBytes).base64EncodedString()
        let expiresAt = Date().addingTimeInterval(60 * 60 * 24 * 30)// 30 días
        let newRefreshToken = RefreshToken(
            userSubsidiaryId: userSubsidiaryId,
            token: refreshToken,
            expiresAt: expiresAt,
            revoked: false
        )
        try await newRefreshToken.save(on: db)
    }
    @discardableResult
    func asociateUser(provider: AuthProvider, googleUser: GoogleUser, on db: any Database) async throws -> UserIdentity? {
        let userIdentities = try await UserIdentity.findUserIdentity(email: googleUser.email, on: db)
        if let userId = userIdentities.first?.user.id {//Existe usuario con este email
            if !userIdentities.contains(where: { $0.provider == provider}) {//No existe el proveedor entonces asociamos
                let newUserIdentity = UserIdentity(
                    userID: userId,
                    provider: provider,
                    providerID: googleUser.id,
                    email: googleUser.email
                )
                try await newUserIdentity.save(on: db)
                return newUserIdentity
            }
        }
        return nil
    }
    private func getUserCompanies(provider: AuthProvider, googleUser: GoogleUser, on db: any Database) async throws -> [CompanyResponseDTO] {
        guard let userIdentity = try await UserIdentity.findUserIdentity(email: googleUser.email, provider: provider, on: db),
              let userId = userIdentity.user.id else {
            return []
        }
        let companies = try await UserSubsidiary.findCompanies(for: userId, on: db)
        let result = try await companies.asyncCompactMap { company -> CompanyResponseDTO? in
            guard let companyId = company.id else {
                return nil
            }
            // Eager load subsidiarias y relaciones
            try await company.$subsidiaries.load(on: db)
            try await company.$user.load(on: db)
            for subsidiary in company.subsidiaries {
                try await subsidiary.$userSubsidiaries.load(on: db)
            }
            return try await CompanyResponseDTO(
                id: companyId,
                company_cic: company.companyCic,
                name: company.name,
                subdomain: company.subdomain,
                is_company_owner: company.user.id == userId,
                subsidaries: company.subsidiaries.asyncCompactMap { subsidiary -> SubsidiaryResponseDTO? in
                    guard let subsidiaryId = subsidiary.id else {
                        return nil
                    }
                    // Eager load subsidiarias y relaciones
                    for userSubsidiary in subsidiary.userSubsidiaries {
                        try await userSubsidiary.$user.load(on: db)
                    }
                    // Encuentra el rol del usuario actual en esa subsidiaria
                    let userSub = subsidiary.userSubsidiaries.first { $0.user.id == userId }
                    return SubsidiaryResponseDTO(
                        id: subsidiaryId,
                        sudsidiary_cic: subsidiary.subsidiaryCic,
                        name: subsidiary.name,
                        subsidiary_role: userSub?.role ?? .employee
                    )
                }
            )
        }
        return result
    }
    //MARK: Private Funtions
    private func extractOAuthParams(from req: Request) throws -> (code: String, state: String?) {
        guard let code = try? req.query.get(String.self, at: "code")//codigo para el token
        else {
            throw Abort(.badRequest, reason: "Missing code")
        }
        let state = try? req.query.get(String.self, at: "state")//subdominio si es registro
        return (code, state)
    }
    private func exchangeCodeForToken(code: String, req: Request) async throws -> GoogleToken {
        guard
            let clientID = Environment.get("GOOGLE_CLIENT_ID"),
            let clientSecret = Environment.get("GOOGLE_CLIENT_SECRET"),
            let redirectURI = Environment.get("GOOGLE_REDIRECT_URI")
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
    private func fetchGoogleUser(token: String, req: Request) async throws -> GoogleUser {
        let userRes = try await req.client.get(URI(string: "https://www.googleapis.com/oauth2/v2/userinfo")) { infoReq in
            infoReq.headers.bearerAuthorization = .init(token: token)
        }
        return try userRes.content.decode(GoogleUser.self)
    }
//    private func buildRedirectURL(user: User, company: Company) -> String {
//        let encodedEmail = user.email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? user.email
//        return "https://\(company.subdomain).mrangel.dev/test"
//    }
}
