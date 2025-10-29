import Fluent
import Vapor

struct SubsidiaryController: RouteCollection {
    let authProviderManager: AuthProviderManager
    let userManipulation: UserManipulation
    let companyManipulation: CompanyManipulation
    func boot(routes: any RoutesBuilder) throws {
        let subsidiary = routes.grouped("subsidiary")
        subsidiary.get(use: selectSubsidiary)
        subsidiary.post(use: registerSubsidiary)
    }
    //Get: subsidiary?id=89fsa78978as78ga789
    @Sendable
    func selectSubsidiary(req: Request) async throws -> ScopedTokenWithRefreshResponse {
        guard let subsidiaryCic = try? req.query.get(String.self, at: "id") else { //?id=89af76f789a9f6aga789
            throw Abort(.badRequest, reason: "Must specify a subsidiary id")
        }
        // Obtener el usuario autenticado del JWT
        let payload = try await req.jwt.verify(as: BaseTokenPayload.self)
        let userCic = payload.sub.value
        //TODO: Select Company and Subsidiary
        let userSubsidiary: UserSubsidiary
        if let workUserSubsidiary = try await UserSubsidiary.getSubsidiaryWhereUserWorks(
            userCic: userCic,
            subsidiaryCic: subsidiaryCic,
            on: req.db
        ) {
            userSubsidiary = workUserSubsidiary
        } else {//Buscamos en la tabla de invitados
            guard let invitation = try await Invitation.findPendingInvitationsInSubsidiary(
                userCic: userCic,
                subsidiaryCic: subsidiaryCic,
                on: req.db
            ) else {
                throw Abort(.badRequest, reason: "user not found in this subsidiary")
            }
            guard let userId = invitation.invitedUser?.id else {
                throw Abort(.internalServerError, reason: "user id not found")
            }
            guard let subsidiaryId = invitation.subsidiary.id else {
                throw Abort(.internalServerError, reason: "subsidiary id not found")
            }
            let newUserSubsidiary = UserSubsidiary(
                userId: userId,
                subsidiaryId: subsidiaryId,
                role: invitation.role,
                status: .active
            )
            invitation.status = .accepted
            try await newUserSubsidiary.save(on: req.db)
            try await invitation.save(on: req.db)
            userSubsidiary = newUserSubsidiary
        }
        //TODO: Cuando selecciona una subsidiaria donde aun no se ha registrado, entonces hay que registrarlo
        let tokenString = try await TokenService.generateScopedToken(userSubsidiary: userSubsidiary, req: req)
        let refreshScopedToken = try await TokenService.getRefreshScopedToken(userSubsidiary: userSubsidiary, req: req)
        return ScopedTokenWithRefreshResponse(scopedToken: tokenString, refreshScopedToken: refreshScopedToken)
    }
    //Post: subsidiary
    @Sendable
    func registerSubsidiary(_ req: Request) async throws -> ScopedTokenWithRefreshResponse {
        let registerDTO = try req.content.decode(RegisterSubsidiaryRequest.self)
        // Obtener el usuario autenticado del JWT
        let payload = try await req.jwt.verify(as: ScopedTokenPayload.self)
        let userCic = payload.sub.value
        let userSubsidiary = try await req.db.transaction { transaction -> UserSubsidiary in
            guard let user: User = try await User.findUser(userCic: userCic, on: transaction),
                  let userId = user.id else {
                throw Abort(.internalServerError, reason: "Failed to find user")
            }
            guard let company = try await Company.findCompany(companyCic: payload.companyCic, on: transaction),
                  let companyId = company.id else {
                throw Abort(.internalServerError, reason: "Failed to find company")
            }
            let newSubsidiary = try await companyManipulation.saveSubsidiary(
                name: registerDTO.subsidiary.name,
                companyId: companyId,
                on: transaction
            )
            guard let subsidiaryId = newSubsidiary.id else {
                throw Abort(.internalServerError, reason: "Failed to generate id for new subsidiary")
            }
            let userSubsidiary = try await companyManipulation.asingUserToSubsidiary(
                userId: userId,
                subsidiaryId: subsidiaryId,
                role: registerDTO.role,
                on: transaction
            )
            return userSubsidiary
        }
        let tokenString = try await TokenService.generateScopedToken(userSubsidiary: userSubsidiary, req: req)
        let refreshScopedToken = try await TokenService.getRefreshScopedToken(userSubsidiary: userSubsidiary, req: req)
        return ScopedTokenWithRefreshResponse(scopedToken: tokenString, refreshScopedToken: refreshScopedToken)
    }
}
