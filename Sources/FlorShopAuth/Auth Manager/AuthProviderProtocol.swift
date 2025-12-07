import Vapor
import Fluent
import FlorShopDTOs

protocol AuthProviderProtocol: Sendable {
    var name: AuthProvider { get }
    func verifyToken(req: Request) async throws -> UserIdentityDTO
}
