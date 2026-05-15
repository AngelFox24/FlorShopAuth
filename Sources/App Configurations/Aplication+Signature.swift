import Vapor
import JWT
import FlorShopDTOs

extension Application {
    public func setSignature() async throws {
        let privateKey = try ES256PrivateKey(pem: String(contentsOfFile: Environment.get(EnvironmentVariables.jwtEcdsaExternalPrivateKeyPath.rawValue)!))
        await self.jwt.keys.add(ecdsa: privateKey, kid: JWTKeyID.externalService.kid)
    }
    public func setVendorVerficationIdentifiers() {
        self.jwt.google.applicationIdentifier = Environment.get(EnvironmentVariables.googleClientId.rawValue)!
    }
}

extension JWTKeyID {
    var kid: JWKIdentifier {
        return JWKIdentifier(string: self.rawValue)
    }
}
