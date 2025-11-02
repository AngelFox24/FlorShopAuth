import Vapor
import JWT

extension Application {
    public func setSignature() async throws {
        guard let privateKeyPath = Environment.get("JWT_PRIVATE_KEY_PATH"),
              let publicKeyPath = Environment.get("JWT_PUBLIC_KEY_PATH") else {
            throw Abort(.internalServerError, reason: "Internal Server Error")
        }
        let privateKey = try ES256PrivateKey(pem: String(contentsOfFile: privateKeyPath))
        let publicKey = try ES256PublicKey(pem: String(contentsOfFile: publicKeyPath))
        await self.jwt.keys.add(ecdsa: privateKey)
    }
}
