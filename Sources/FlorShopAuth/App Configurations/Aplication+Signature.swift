import Vapor
import JWT

extension Application {
    public func setSignature() async throws {
        guard let privateKeyPath = Environment.get("JWT_PRIVATE_KEY_PATH") else {
            fatalError("JWT_PRIVATE_KEY_PATH don't found in .env.\(self.environment)")
        }
        let privateKey = try ES256PrivateKey(pem: String(contentsOfFile: privateKeyPath))
        await self.jwt.keys.add(ecdsa: privateKey)
    }
    public func setVendorVerficationIdentifiers() async throws {
        guard let googleClientId = Environment.get("GOOGLE_CLIENT_ID") else {
            fatalError("GOOGLE_CLIENT_ID don't found in .env.\(self.environment)")
        }
        self.jwt.google.applicationIdentifier = googleClientId
    }
}
