import Foundation
import Vapor
import FlorShop_DTOs

struct RegisterRequest: Content {
    let authentication: AuthenticationDTO
    let company: CompanyServerDTO
    let subsidiary: SubsidiaryServerDTO
    let role: UserSubsidiaryRole
    let subdomain: String
}

struct AuthenticationDTO: Content {
    let token: String
    let provider: AuthProvider
}
