import Vapor
import FlorShopDTOs

struct InvitationRequest: Content {
    let email: String
    let role: UserSubsidiaryRole
}
