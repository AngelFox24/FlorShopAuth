import Vapor
import JWT
import JWTKit

struct GoogleTokenVerifier {
    static let jwksURL = URI(string: "https://www.googleapis.com/oauth2/v3/certs")

    static func verify(idToken: String, on client: any Client) async throws -> GoogleUser {
        // 1️⃣ Obtener las llaves públicas (puedes cachearlas luego)
        let jwksResponse = try await client.get(jwksURL)
        let jwks = try jwksResponse.content.decode(JWKS.self)

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
        let payload = try await keyCollection.verify(idToken, as: GoogleIDToken.self)

        // 5️⃣ Validar la audiencia (client_id de tu app)
        guard let clientID = Environment.get("GOOGLE_CLIENT_ID"),
              payload.audience.value.contains(clientID) else {
            throw Abort(.unauthorized, reason: "Invalid audience (client ID mismatch)")
        }
        // 6️⃣ Crear el objeto GoogleUser
        return GoogleUser(
            id: payload.subject.value,
            email: payload.email,
            name: payload.name,
            picture: payload.picture
        )
    }
}
