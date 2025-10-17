import Vapor

struct BaseTokenResponse: Content {
    let baseToken: String
}

struct ListCompanyResponse: Content {
    let baseToken: String
    let companies: [CompanyResponseDTO]
}

struct ScopedTokenResponse: Content {
    let scopedToken: String
}

struct ScopedTokenWithRefreshResponse: Content {
    let scopedToken: String
    let refreshScopedToken: String
}

struct CompanyResponseDTO: Content {
    let id: UUID
    let company_cic: String
    let name: String
    let subdomain: String
    let is_company_owner: Bool
    let subsidaries: [SubsidiaryResponseDTO]
}

struct SubsidiaryResponseDTO: Content {
    let id: UUID
    let sudsidiary_cic: String
    let name: String
    let subsidiary_role: UserSubsidiaryRole
}
