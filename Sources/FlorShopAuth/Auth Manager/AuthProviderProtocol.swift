import Vapor
import Fluent

protocol AuthProviderProtocol: Sendable {
    var name: AuthProvider { get }
    func verifyToken(req: Request) async throws -> UserIdentityDTO
}
