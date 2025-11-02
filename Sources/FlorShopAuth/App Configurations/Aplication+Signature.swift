import Vapor
import JWT

extension Application {
    public func setSignature() async throws {
        guard let privateKeyPath = Environment.get("JWT_PRIVATE_KEY_PATH") else {
            throw Abort(.internalServerError, reason: "Internal Server Error")
        }
        let privateKey = try ES256PrivateKey(pem: String(contentsOfFile: privateKeyPath))
        await self.jwt.keys.add(ecdsa: privateKey)
    }
    public func setVendorVerficationIdentifiers() async throws {
        // Configuración de Google JWT
        guard let googleClientId = Environment.get("GOOGLE_CLIENT_ID") else {
            throw Abort(.internalServerError, reason: "google client id don't found")
        }
        self.jwt.google.applicationIdentifier = googleClientId
    }
}
