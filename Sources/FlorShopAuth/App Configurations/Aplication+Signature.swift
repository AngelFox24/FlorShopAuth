import Vapor
import JWT
import FlorShopDTOs

extension Application {
    public func setSignature() async throws {
        guard let privateKeyPath = Environment.get(EnvironmentVariables.jwtEcdsaExternalPrivateKeyPath.rawValue) else {
            fatalError("\(EnvironmentVariables.jwtEcdsaExternalPrivateKeyPath.rawValue) don't found in .env.\(self.environment)")
        }
        let privateKey = try ES256PrivateKey(pem: String(contentsOfFile: privateKeyPath))
        await self.jwt.keys.add(ecdsa: privateKey, kid: JWTKeyID.externalService.kid)
        
        guard let internalKey = Environment.get(EnvironmentVariables.jwtHmacInternalKey.rawValue) else {
            fatalError("\(EnvironmentVariables.jwtHmacInternalKey.rawValue) don't found in .env.\(self.environment)")
        }
        let hmacKey = HMACKey(from: internalKey)
        await self.jwt.keys.add(hmac: hmacKey, digestAlgorithm: .sha256, kid: JWTKeyID.internalToken.kid)
    }
    public func setVendorVerficationIdentifiers() async throws {
        guard let googleClientId = Environment.get(EnvironmentVariables.googleClientId.rawValue) else {
            fatalError("\(EnvironmentVariables.googleClientId.rawValue) don't found in .env.\(self.environment)")
        }
        self.jwt.google.applicationIdentifier = googleClientId
    }
}

extension JWTKeyID {
    var kid: JWKIdentifier {
        return JWKIdentifier(string: self.rawValue)
    }
}
