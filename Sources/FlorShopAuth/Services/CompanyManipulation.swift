import Vapor
import Fluent
import FlorShopDTOs

struct CompanyManipulation {
    func saveCompany(companyName: String, subdomain: String, ownerId: UUID, on db: any Database) async throws -> Company {
        try await Company.validateCompanyNotExist(
            name: companyName,
            subdomain: subdomain,
            on: db
        )
        let companyCic = UUID().uuidString
        let newCompany = Company(
            userId: ownerId,
            companyCic: companyCic,
            name: companyName,
            subdomain: subdomain
        )
        try await newCompany.save(on: db)
        return newCompany
    }
    func saveSubsidiary(name: String, companyId: UUID, on db: any Database) async throws -> Subsidiary {
        guard try await !Subsidiary.subsidiaryExist(name: name, companyId: companyId, on: db) else {
            throw Abort(.badRequest, reason: "This name is already in use")
        }
        let subsidiaryCic = UUID().uuidString
        let newSusidiary = Subsidiary(
            companyId: companyId,
            subsidiaryCic: subsidiaryCic,
            name: name
        )
        try await newSusidiary.save(on: db)
        return newSusidiary
    }
    func asingUserToSubsidiary(userId: UUID, subsidiaryId: UUID, role: UserSubsidiaryRole, on db: any Database) async throws -> UserSubsidiary {
        //TODO: Validate and obtain a relationship to update with new role
        let newUserSubsidiary = UserSubsidiary(
            userId: userId,
            subsidiaryId: subsidiaryId,
            role: role,
            status: .active
        )
        try await newUserSubsidiary.save(on: db)
        return newUserSubsidiary
    }
    func getUserCompanies(userCic: String, on db: any Database) async throws -> [CompanyResponseDTO] {
        let companies = try await Company.listUserWorkCompanies(userCic: userCic, on: db)
        var companiesResponse: [CompanyResponseDTO] = []
        for company in companies {
            let companyDTO = CompanyResponseDTO(
                company_cic: company.companyCic,
                name: company.name,
                subdomain: company.subdomain,
                is_company_owner: company.user.userCic == userCic
            )
            companiesResponse.append(companyDTO)
        }
        return companiesResponse
    }
    func getUserSubsidiaries(userCic: String, companyCic: String, on db: any Database) async throws -> [SubsidiaryResponseDTO] {
        let subsidiaries: [Subsidiary] = try await Subsidiary.listUserWorkSubsidiaries(userCic: userCic, companyCic: companyCic, on: db)
        var subsidiaryResponse: [SubsidiaryResponseDTO] = []
        for subsidiary in subsidiaries {
            guard let role = subsidiary.userSubsidiaries.first?.role else { continue }
            let subsidiaryDTO = SubsidiaryResponseDTO(
                subsidiary_cic: subsidiary.subsidiaryCic,
                name: subsidiary.name,
                subsidiary_role: role
            )
            subsidiaryResponse.append(subsidiaryDTO)
        }
        return subsidiaryResponse
    }
    func getUserCompaniesInvitations(userCic: String, on db: any Database) async throws -> [CompanyResponseDTO] {
        let companies = try await Company.listUserInvitedCompanies(userCic: userCic, on: db)
        var companiesResponse: [CompanyResponseDTO] = []
        for company in companies {
            let companyDTO = CompanyResponseDTO(
                company_cic: company.companyCic,
                name: company.name,
                subdomain: company.subdomain,
                is_company_owner: company.user.userCic == userCic
            )
            companiesResponse.append(companyDTO)
        }
        return companiesResponse
    }
    func getUserSubsidiariesInvitations(userCic: String, companyCic: String, on db: any Database) async throws -> [SubsidiaryResponseDTO] {
        let subsidiaries = try await Subsidiary.listUserInvitedSubsidiaries(userCic: userCic, companyCic: companyCic, on: db)
        var subsidiaryResponse: [SubsidiaryResponseDTO] = []
        for subsidiary in subsidiaries {
            guard let role = subsidiary.userSubsidiaries.first?.role else { continue }
            let subsidiaryDTO = SubsidiaryResponseDTO(
                subsidiary_cic: subsidiary.subsidiaryCic,
                name: subsidiary.name,
                subsidiary_role: role
            )
            subsidiaryResponse.append(subsidiaryDTO)
        }
        return subsidiaryResponse
    }
    func getUserCompaniesWithInvitations(userCic: String, on db: any Database) async throws -> [CompanyResponseDTO] {
        let workCompanies = try await getUserCompanies(userCic: userCic, on: db)
        let invitedCompanies = try await getUserCompaniesInvitations(userCic: userCic, on: db)
        var mergedCompanies: [String: CompanyResponseDTO] = [:] // key = company_cic
        for company in workCompanies {
            mergedCompanies[company.company_cic] = company
        }
        for invited in invitedCompanies {
            if !mergedCompanies.contains(where: { $0.key == invited.company_cic }) {
                mergedCompanies[invited.company_cic] = invited
            }
        }
        return Array(mergedCompanies.values)
    }
    func getUserSubsidiariesWithInvitations(userCic: String, companyCic: String, on db: any Database) async throws -> [SubsidiaryResponseDTO] {
        let workSubsidiaries = try await getUserSubsidiaries(userCic: userCic, companyCic: companyCic, on: db)
        let invitedSubsidiaries = try await getUserSubsidiariesInvitations(userCic: userCic, companyCic: companyCic, on: db)
        var mergedSubsidiaries: [String: SubsidiaryResponseDTO] = [:] // key = company_cic
        for subsidiary in workSubsidiaries {
            mergedSubsidiaries[subsidiary.subsidiary_cic] = subsidiary
        }
        for invited in invitedSubsidiaries {
            if !mergedSubsidiaries.contains(where: { $0.key == invited.subsidiary_cic }) {
                mergedSubsidiaries[invited.subsidiary_cic] = invited
            }
        }
        return Array(mergedSubsidiaries.values)
    }
}
