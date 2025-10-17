import Vapor
import Fluent
import JWT

actor GoogleAuthProvider: AuthProviderProtocol {
    let name = AuthProvider.google
    private let jwksURL = URI(string: "https://www.googleapis.com/oauth2/v3/certs")
    private var cachedJWKS: JWKS?
    private var eTag: String?
    private var expirationDate: Date?
    
    func verifyToken(_ token: String, client: any Client) async throws -> UserIdentityDTO {
        // 1️⃣ Obtener las llaves públicas (puedes cachearlas luego)
        let jwks = try await getJWKS(client: client)

        // 2️⃣ Configurar los signers con esas llaves
        let keyCollection = JWTKeyCollection()
        try await keyCollection.add(jwks: jwks)

        // 3️⃣ Decodificar y validar el JWT
        struct GoogleIDToken: JWTPayload {
            enum CodingKeys: String, CodingKey {
                case issuer = "iss"
                case subject = "sub"
                case email
                case emailVerified = "email_verified"
                case name
                case picture
                case audience = "aud"
                case expiration = "exp"
                case issuedAt = "iat"
            }

            var issuer: IssuerClaim
            var subject: SubjectClaim
            var email: String
            var emailVerified: Bool
            var name: String?
            var picture: String?
            var audience: AudienceClaim
            var expiration: ExpirationClaim
            var issuedAt: IssuedAtClaim

            func verify(using signer: some JWTAlgorithm) throws {
                try expiration.verifyNotExpired()
                guard issuer.value == "https://accounts.google.com" ||
                      issuer.value == "accounts.google.com" else {
                    throw Abort(.unauthorized, reason: "Invalid issuer")
                }
            }
        }

        // 4️⃣ Verificar la firma y decodificar el payload
        let payload = try await keyCollection.verify(token, as: GoogleIDToken.self)

        // 5️⃣ Validar la audiencia (client_id de tu app)
        guard let clientID = Environment.get("GOOGLE_CLIENT_ID"),
              payload.audience.value.contains(clientID) else {
            throw Abort(.unauthorized, reason: "Invalid audience (client ID mismatch)")
        }
        // 6️⃣ Crear el objeto GoogleUser
        return UserIdentityDTO(
            id: payload.subject.value,
            email: payload.email,
            name: payload.name,
            picture: payload.picture
        )
    }
    private func getJWKS(client: any Client) async throws -> JWKS {
        // ✅ Si sigue siendo válido según Cache-Control
        if let cachedJWKS, let expirationDate, Date() < expirationDate {
            return cachedJWKS
        }
        
        var headers = HTTPHeaders()
        if let eTag {
            headers.add(name: .ifNoneMatch, value: eTag)
        }
        
        let response = try await client.get(jwksURL, headers: headers)
        
        if response.status == .notModified, let cachedJWKS {
            // 🔁 Reusar cache
            return cachedJWKS
        }
        
        // 🆕 Actualizar cache
        let jwks = try response.content.decode(JWKS.self)
        cachedJWKS = jwks
        
        // Leer encabezados HTTP
        if let cacheControl = response.headers.first(name: .cacheControl),
           let maxAge = parseMaxAge(from: cacheControl) {
            expirationDate = Date().addingTimeInterval(TimeInterval(maxAge))
        }
        
        eTag = response.headers.first(name: .eTag)
        return jwks
    }
    private func parseMaxAge(from cacheControl: String) -> Int? {
        // Ejemplo: "public, max-age=12345"
        let parts = cacheControl.split(separator: ",")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("max-age="),
               let value = Int(trimmed.replacingOccurrences(of: "max-age=", with: "")) {
                return value
            }
        }
        return nil
    }
}
