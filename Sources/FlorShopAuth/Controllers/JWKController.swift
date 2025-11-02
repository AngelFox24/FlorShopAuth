import Vapor
import JWT
import Crypto

struct JWKController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let invitation = routes.grouped("auth")
        invitation.get(use: getKeys)
    }

    func getKeys(req: Request) throws -> Response {
        guard let publicKeyPath = Environment.get("JWT_PUBLIC_KEY_PATH") else {
            throw Abort(.internalServerError, reason: "Public key not found")
        }

        let publicKey = try ES256PublicKey(pem: String(contentsOfFile: publicKeyPath))
        guard let parameters = publicKey.parameters else {
            throw Abort(.internalServerError, reason: "Public don't have parameters")
        }
        let jwkJSON = """
        {
            "keys": [
                {
                    "kty": "EC",
                    "use": "sig",
                    "alg": "ES256",
                    "kid": "key1",
                    "crv": "P-256",
                    "x": "\(parameters.x)",
                    "y": "\(parameters.y)"
                }
            ]
        }
        """
        let response = Response()
        response.headers.add(name: .contentType, value: "application/json")
        response.body = .init(string: jwkJSON)
        return response
    }
}
