import Vapor
import Fluent
protocol AuthProviderProtocol: Sendable {
    var name: AuthProvider { get }
    func verifyToken(_ token: String, client: any Client) async throws -> UserIdentityDTO
}
