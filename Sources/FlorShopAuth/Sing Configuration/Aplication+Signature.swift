import Vapor
import JWT

extension Application {
    public func setSignature() async throws {
        guard let secret = Environment.get("JWT_SECRET") else {
            self.logger.critical("Missing JWT_SECRET")
            throw Abort(.internalServerError, reason: "Internal Server Error")
        }
        await self.jwt.keys.add(hmac: HMACKey(stringLiteral: secret), digestAlgorithm: .sha256)
    }
}
