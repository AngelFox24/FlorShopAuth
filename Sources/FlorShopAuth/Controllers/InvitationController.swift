import Fluent
import Vapor

struct InvitationController: RouteCollection {
    let authProviderManager: AuthProviderManager
    let userManipulation: UserManipulation
    func boot(routes: any RoutesBuilder) throws {
        let invitation = routes.grouped("invitation")
        invitation.post(use: registerInvitation)
    }
    //Post: invitation
    @Sendable
    func registerInvitation(_ req: Request) async throws -> Response {
        let payload = try await req.jwt.verify(as: ScopedTokenPayload.self)//Validate token
        //TODO: Validate ScopedToken
        guard let user = try await User.findUser(userCic: payload.sub.value, on: req.db),
              let userId = user.id else {
            throw Abort(.badRequest, reason: "user not found")
        }
        guard let subsidiaryCic = payload.subsidiaryCic,
              let subsidiary = try await Subsidiary.findSubsidiary(subsidiaryCic: subsidiaryCic, on: req.db),
              let subsidiaryId = subsidiary.id else {
            throw Abort(.badRequest, reason: "subsidiary not found")
        }
        let invitationRequest = try req.content.decode(InvitationRequest.self)
        let invitedUser: UserIdentity? = try await UserIdentity.findUserIdentity(email: invitationRequest.email, on: req.db)
        let expirationData = Date().addingTimeInterval(60 * 60 * 24 * 10)//10 dias
        //TODO: Validar que no existe ese usuario como invitado
        let newInvitation = Invitation(
            invitedByUserId: userId,
            invitedUserId: invitedUser?.id,//si el usuario invitado si tiene registro se le asigna
            subsidiaryId: subsidiaryId,
            email: invitationRequest.email,
            role: invitationRequest.role,
            status: .pending,
            expiredAt: expirationData
        )
        try await newInvitation.save(on: req.db)
        return Response(status: .ok)
    }
    //Get: invitation
    /*
     Los usuarios que han sido invitados con solo su correo primero ingresan por AuthController para obtener el BaseToken y
     alli mismo se registra como nuevo usuario y las invitacion se asocian a ese usuario, asi que solo se debe buscar las
     invitaciones que esten pendientes y que el usuario invitado sea el que tiene en el BaseToken
     */
//    @Sendable
//    func getInvitations(_ req: Request) async throws -> [CompanyResponseDTO] {
//        let payload = try await req.jwt.verify(as: BaseTokenPayload.self)//Validate token
//        //TODO: Validate BaseToken
//        guard let user = try await User.findUser(
//            userCic: payload.sub.value,
//            on: req.db
//        ) else {//si no encuentra al usuario es porque hay un error grave porque no debe emitirse un base token de un usuario no registrado
//            throw Abort(.badRequest, reason: "user don't have invitations")
//        }
//        let invitations = try await Invitation.findPendingInvitations(userCic: user.userCic, on: req.db)
//        let response = try await invitations.asyncCompactMap { invitation -> CompanyResponseDTO? in
//            // Eager load subsidiarias y relaciones
//            let subsidiary = try await invitation.$subsidiary.get(on: req.db)
//            let company = try await subsidiary.$company.get(on: req.db)
//            let owner = try await company.$user.get(on: req.db)
//            guard let companyId = company.id else {
//                Logger(label: "Invitation List").error("companyId not found")
//                return nil
//            }
//            return CompanyResponseDTO(
//                id: companyId,
//                company_cic: company.companyCic,
//                name: company.name,
//                subdomain: company.subdomain,
//                is_company_owner: user.userCic == owner.userCic,
//                subsidaries: <#T##[SubsidiaryResponseDTO]#>
//            )
//        }
//    }
}
