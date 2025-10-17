import Vapor
import JWT
import CryptoKit

public enum EnvironmentType {
    case development
    case production
}

extension Application {
    public func setSignature() async throws {
        let secretData: Data
        // Configura el signer global (HMAC SHA-256) usando tu secreto
        switch self.environment {
        case .production:
            guard let secret = Environment.get("JWT_SECRET"),
            let secretDataUtf8 = secret.data(using: .utf8) else {
                self.logger.critical("Missing JWT_SECRET")
                throw Abort(.internalServerError, reason: "Internal Server Error")
            }
            secretData = secretDataUtf8
        default://development
            let secret = "NUZUQGyG9i0WwwpajrGXVnVmuXpkE6tkDp6b6Wuf5Y0gTcNYQzygKW3YvqxLPUDVUGuRTxo2mppM913HbeEz"
            guard let secretDataUtf8 = secret.data(using: .utf8) else {
                self.logger.critical("Can't convert JWT_SECRET to Data")
                throw Abort(.internalServerError, reason: "Internal Server Error")
            }
            secretData = secretDataUtf8
        }
        let key = SymmetricKey(data: secretData)
        let hmacKey = HMACKey(key: key)
        await self.jwt.keys.add(hmac: hmacKey, digestAlgorithm: .sha256)
    }
}
