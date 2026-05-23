import Vapor
import FlorShopDTOs
import FlorShopNetworking

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
        let cic = company.grouped("cic")
        cic.get(use: getUserCompany)
    }
    
    //MARK: GET: company
    @Sendable
    func getUserCompanies(_ req: Request) async throws -> [CompanyResponseDTO] {
        let payload = try await req.jwt.selfflorshop.verifyBaseToken()
        let companies: [CompanyResponseDTO] = try await companyManipulation.getUserCompaniesWithInvitations(
            userCic: payload.sub.value,
            on: req.db
        )
        return companies
    }
    //MARK: GET: /company/cic?companyCic=3293F1F2-F6D9-4386-8CC9-857448F5618E
    @Sendable
    func getUserCompany(_ req: Request) async throws -> CompanyResponseDTO {
        guard let companyCic = try? req.query.get(String.self, at: "companyCic") else {
            throw Abort(.badRequest, reason: "Must specify a companyCic id")
        }
        guard let baseTokenStr = req.headers.first(name: HTTPHeader.baseToken.rawValue) else {
            throw Abort(.unauthorized, reason: "Missing user token")
        }
        let _ = try await req.jwt.selfflorshop.verify()
        let baseToken = try await req.jwt.selfflorshop.verifyBaseToken(baseTokenStr)
        guard let company = try await Company.getUserCompany(companyCic: companyCic, userCic: baseToken.sub.value, on: req.db) else {
            throw Abort(.notFound, reason: "Company not found")
        }
        return company.toDTO(userCic: baseToken.sub.value)
    }
    //MARK: POST: company
    @Sendable
    func updateCompany(_ req: Request) async throws -> DefaultResponse {
        guard let scopedTokenStr = req.headers.first(name: HTTPHeader.scopedToken.rawValue) else {
            throw Abort(.unauthorized, reason: "Missing user scopedToken")
        }
        let _ = try await req.jwt.selfflorshop.verify()
        let scopedToken = try await req.jwt.selfflorshop.verifyScopedToken(scopedTokenStr)
        let companyDTO = try req.content.decode(CompanyServerDTO.self)
        guard try await !Company.companyNameExist(name: companyDTO.companyName, on: req.db) else {
            throw Abort(.badRequest, reason: "Company name already exist")
        }
        guard let company = try await Company.findCompany(companyCic: scopedToken.companyCic, on: req.db) else {
            throw Abort(.badRequest, reason: "Company not found")
        }
        company.name = companyDTO.companyName
        try await company.save(on: req.db)
        return DefaultResponse()
    }
    //MARK: POST: company/register
    @Sendable
    func registerCompany(_ req: Request) async throws -> ScopedTokenWithRefreshResponse {
        let payload = try await req.jwt.selfflorshop.verifyBaseToken()
        let registerDTO = try req.content.decode(RegisterCompanyRequest.self)
        //TODO: Validate Payment
        let userSubsidiary = try await req.db.transaction { transaction -> UserSubsidiary in
            guard let user: User = try await User.findUser(userCic: payload.sub.value, on: transaction) else {
                throw Abort(.badRequest, reason: "User not exist")
            }
            guard let userId = user.id else {
                throw Abort(.internalServerError, reason: "Failed to generate Id for user")
            }
            //user want to create a new company
            let newCompany = try await companyManipulation.saveCompany(
                companyName: registerDTO.company.companyName,
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
