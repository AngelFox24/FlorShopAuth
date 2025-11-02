import Vapor
import JWT

actor GoogleAuthProvider: AuthProviderProtocol {
    let name = AuthProvider.google    
    func verifyToken(_ token: String, req: Request) async throws -> UserIdentityDTO {
        let token: GoogleIdentityToken = try await req.jwt.google.verify()
        guard let userIdentityDTO = token.toUserIdentityDTO() else {
            throw Abort(.unauthorized, reason: "google token malformatted")
        }
        return userIdentityDTO
    }
}
