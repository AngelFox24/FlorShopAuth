import Vapor

struct CompanySelectionRequest: Content {
    let companyId: UUID
}

struct RefreshTokenRequest: Content {
    let refreshScopedToken: String
}
