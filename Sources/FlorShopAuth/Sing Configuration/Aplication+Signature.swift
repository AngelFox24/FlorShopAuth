import Vapor
import JWT
import CryptoKit

extension Application {
    public func setSignature() async throws {
        guard let secret = Environment.get("JWT_SECRET"),
              let secretDataUtf8 = secret.data(using: .utf8) else {
            self.logger.critical("Missing JWT_SECRET")
            throw Abort(.internalServerError, reason: "Internal Server Error")
        }
        let key = SymmetricKey(data: secretDataUtf8)
        let hmacKey = HMACKey(key: key)
        await self.jwt.keys.add(hmac: hmacKey, digestAlgorithm: .sha256)
    }
}
