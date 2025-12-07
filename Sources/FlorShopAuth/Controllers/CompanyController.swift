import Vapor
import FlorShopDTOs

struct CompanyController: RouteCollection {
    let authProviderManager: AuthProviderManager
    let userManipulation: UserManipulation
    let companyManipulation: CompanyManipulation
    func boot(routes: any RoutesBuilder) throws {
        let company = routes.grouped("company")
        company.get(use: getUserCompanies)
        company.post(use: updateCompany)
        let register = company.grouped("register")
        register.post(use: registerCompany)
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
    func updateCompany(_ req: Request) async throws -> DefaultResponse {
        let payload = try await req.jwt.verify(as: InternalPayload.self)
        let companyDTO = try req.content.decode(CompanyServerDTO.self)
        guard try await !Company.companyNameExist(name: companyDTO.companyName, on: req.db) else {
            throw Abort(.badRequest, reason: "Company name already exist")
        }
        guard let company = try await Company.findCompany(companyCic: payload.companyCic, on: req.db) else {
            throw Abort(.badRequest, reason: "Company not found")
        }
        company.name = companyDTO.companyName
        try await company.save(on: req.db)
        return DefaultResponse()
    }
    //Post: company/register
    @Sendable
    func registerCompany(_ req: Request) async throws -> ScopedTokenWithRefreshResponse {
        let registerDTO = try req.content.decode(RegisterCompanyRequest.self)
        let userIdentityDTO = try await authProviderManager.verifyToken(
            using: registerDTO.provider,
            on: req
        )
        //TODO: Validate Payment
        let userSubsidiary = try await req.db.transaction { transaction -> UserSubsidiary in
            let user: User = try await userManipulation.saveUser(
                provider: registerDTO.provider,
                userIdentityDTO: userIdentityDTO,
                on: transaction
            )
            guard let userId = user.id else {
                throw Abort(.internalServerError, reason: "Failed to generate Id for user")
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
