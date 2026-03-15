import Vapor
import JWT
import FlorShopDTOs

actor GoogleAuthProvider: AuthProviderProtocol {
    let name = AuthProvider.google    
    func verifyToken(req: Request) async throws -> UserIdentityDTO {
        let token: GoogleIdentityToken = try await req.jwt.google.verify()
        guard let userIdentityDTO = token.toUserIdentityDTO() else {
            throw Abort(.unauthorized, reason: "google token malformatted")
        }
        return userIdentityDTO
    }
    func verifyToken(token: String, req: Request) async throws -> UserIdentityDTO {
        let token: GoogleIdentityToken = try await req.jwt.google.verify(token)
        guard let userIdentityDTO = token.toUserIdentityDTO() else {
            throw Abort(.unauthorized, reason: "google token malformatted")
        }
        return userIdentityDTO
    }
}
