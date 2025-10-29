import Foundation
import Vapor
import FlorShop_DTOs

struct RegisterCompanyRequest: Content {
    let authentication: AuthenticationDTO
    let company: CompanyServerDTO
    let subsidiary: SubsidiaryServerDTO
    let role: UserSubsidiaryRole
    let subdomain: String
}

struct RegisterSubsidiaryRequest: Content {
    let subsidiary: SubsidiaryServerDTO
    let role: UserSubsidiaryRole
}

struct AuthenticationDTO: Content {
    let token: String
    let provider: AuthProvider
}
