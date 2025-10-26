import Vapor

struct InvitationRequest: Content {
    let email: String
    let role: UserSubsidiaryRole
}
