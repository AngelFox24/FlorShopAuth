import Vapor
import JWT

actor AppleAuthProvider: AuthProviderProtocol {
    let name = AuthProvider.apple
    func verifyToken(req: Request) async throws -> UserIdentityDTO {
        let token: AppleIdentityToken = try await req.jwt.apple.verify()
        guard let userIdentityDTO = token.toUserIdentityDTO() else {
            throw Abort(.unauthorized, reason: "apple token malformatted")
        }
        return userIdentityDTO
    }
}
