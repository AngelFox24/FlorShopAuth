import JWT
import Vapor

struct GoogleTokenPayload: JWTPayload {
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
