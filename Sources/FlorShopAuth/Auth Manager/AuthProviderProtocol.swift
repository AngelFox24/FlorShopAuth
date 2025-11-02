import Vapor
import Fluent

protocol AuthProviderProtocol: Sendable {
    var name: AuthProvider { get }
    func verifyToken(_ token: String, req: Request) async throws -> UserIdentityDTO
}
