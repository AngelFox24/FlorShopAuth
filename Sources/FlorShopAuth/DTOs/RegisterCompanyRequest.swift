import Vapor
import FlorShopDTOs

struct RegisterCompanyRequest: Content {
    let provider: AuthProvider
    let company: CompanyServerDTO
    let subsidiary: SubsidiaryServerDTO
    let role: UserSubsidiaryRole
    let subdomain: String
}

struct RegisterSubsidiaryRequest: Content {
    let subsidiary: SubsidiaryServerDTO
    let role: FlorShopDTOs.UserSubsidiaryRole
}
