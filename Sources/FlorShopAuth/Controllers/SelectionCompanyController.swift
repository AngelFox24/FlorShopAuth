import Fluent
import Vapor
import JWT

struct SelectionCompanyController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let selection = routes.grouped("selection-company")
        selection.get(use: selectCompany)
    }
    @Sendable
    func selectCompany(req: Request) async throws -> ScopedTokenWithRefreshResponse {
        // Decodificar el cuerpo
        guard let companyIdString = try? req.query.get(String.self, at: "id"),
              let companyId = UUID(uuidString: companyIdString) else {
            throw Abort(.badRequest, reason: "Must specify a company")
        }
        // Obtener el usuario autenticado del JWT
        let payload = try await req.jwt.verify(as: BaseTokenPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value) else {
            throw Abort(.internalServerError, reason: "Can't parse userId from JWT")
        }
        //TODO: Select Company and Subsidiary
        let result = try await getUserAndSubsidiary(userId: userId, subsidiaryId: companyId, on: req.db)
        let tokenString = try await TokenService.generateScopedToken(for: result.user, subsidiary: result.subsidiary, req: req)
        let refreshScopedToken = try await TokenService.getRefreshScopedToken(for: result.user, subsidiary: result.subsidiary, req: req)
        return ScopedTokenWithRefreshResponse(scopedToken: tokenString, refreshScopedToken: refreshScopedToken)
    }
    private func getUserAndSubsidiary(userId: UUID, subsidiaryId: UUID, on db: any Database) async throws -> (user: User, subsidiary: Subsidiary) {
        // Validar que esa company pertenece a ese usuario
        try await UserSubsidiary.validateUserWorksAtSubsidiary(userId: userId, subsidiaryId: subsidiaryId, on: db)
        guard let user = try await User.findUser(userId: userId, on: db) else {
            throw Abort(.badRequest, reason: "User not found")
        }
        guard let subsidiary = try await Subsidiary.findSubsidiary(subsidiaryId: subsidiaryId, on: db) else {
            throw Abort(.badRequest, reason: "Subsidiary not found")
        }
        return (user, subsidiary)
    }
}
