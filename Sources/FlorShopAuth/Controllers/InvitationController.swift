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
        //TODO: Validate ScopedToken role
        guard let user = try await User.findUser(userCic: payload.sub.value, on: req.db),
              let userId = user.id else {
            throw Abort(.badRequest, reason: "user not found")
        }
        guard let subsidiary = try await Subsidiary.findSubsidiary(subsidiaryCic: payload.subsidiaryCic, on: req.db),
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
}
