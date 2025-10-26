import Fluent
import Vapor

struct CompanyController: RouteCollection {
    let authProviderManager: AuthProviderManager
    let userManipulation: UserManipulation
    let companyManipulation: CompanyManipulation
    func boot(routes: any RoutesBuilder) throws {
        let company = routes.grouped("company")
        company.get(use: getUserCompanies)
        company.post(use: registerCompany)
    }
    
    //Get: company
    @Sendable
    func getUserCompanies(_ req: Request) async throws -> [CompanyResponseDTO] {
        let payload = try await req.jwt.verify(as: BaseTokenPayload.self)
        let companies: [CompanyResponseDTO] = try await companyManipulation.getUserCompaniesWithInvitations(
            userCic: payload.sub.value,
            on: req.db
        )
        return companies
    }

    //Post: company
    @Sendable
    func registerCompany(_ req: Request) async throws -> ScopedTokenWithRefreshResponse {
        let registerDTO = try req.content.decode(RegisterRequest.self)
        let userIdentityDTO = try await authProviderManager.verifyToken(
            registerDTO.authentication.token,
            using: registerDTO.authentication.provider,
            on: req
        )
        //TODO: Validate Payment
        let userSubsidiary = try await req.db.transaction { transaction -> UserSubsidiary in
            let user: User = try await userManipulation.saveUser(
                provider: registerDTO.authentication.provider,
                userIdentityDTO: userIdentityDTO,
                on: transaction
            )
            guard let userId = user.id else {
                throw Abort(.internalServerError, reason: "Failed to generate Id for user")
            }
            guard registerDTO.company.id == nil else {
                throw Abort(.badGateway, reason: "company id should not be provided")
            }
            //user want to create a new company
            let newCompany = try await companyManipulation.saveCompany(
                companyName: registerDTO.company.companyName,
                subdomain: registerDTO.subdomain,
                ownerId: userId,
                on: transaction
            )
            guard let companyId = newCompany.id else {
                throw Abort(.internalServerError, reason: "Failed to generate id for new company")
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
