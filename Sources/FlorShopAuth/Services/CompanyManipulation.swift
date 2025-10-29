import Vapor
import Fluent

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
        //TODO: Validate don't exist
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
    //TODO: Buscar en la tabla de invitados para agregar a esta lista
    func getUserCompanies(userCic: String, on db: any Database) async throws -> [CompanyResponseDTO] {
        let companies = try await Company.listUserWorkCompanies(userCic: userCic, on: db)
        var companiesResponse: [CompanyResponseDTO] = []
        for company in companies {
            guard let companyId = company.id else { continue }
            var subsidiariesDTO: [SubsidiaryResponseDTO] = []
            for subsidiary in company.subsidiaries {
                guard subsidiary.userSubsidiaries.count == 1 else {
                    Logger(label: "CompanyManipulation").warning("Subsidiary has more than one userSubsidiary relationship with this user")
                    continue
                }
                guard let subsidiaryId = subsidiary.id,
                let role = subsidiary.userSubsidiaries.first?.role else { continue }
                let subsidiaryDTO = SubsidiaryResponseDTO(
                    id: subsidiaryId,
                    subsidiary_cic: subsidiary.subsidiaryCic,
                    name: subsidiary.name,
                    subsidiary_role: role
                )
                subsidiariesDTO.append(subsidiaryDTO)
            }
            guard !subsidiariesDTO.isEmpty else { continue }
            let companyDTO = CompanyResponseDTO(
                id: companyId,
                company_cic: company.companyCic,
                name: company.name,
                subdomain: company.subdomain,
                is_company_owner: company.user.userCic == userCic,
                subsidaries: subsidiariesDTO
            )
            companiesResponse.append(companyDTO)
        }
        return companiesResponse
    }
    func getUserInvitations(userCic: String, on db: any Database) async throws -> [CompanyResponseDTO] {
        let companies = try await Company.listUserInvitedCompanies(userCic: userCic, on: db)
        var companiesResponse: [CompanyResponseDTO] = []
        for company in companies {
            guard let companyId = company.id else { continue }
            var subsidiariesDTO: [SubsidiaryResponseDTO] = []
            for subsidiary in company.subsidiaries {
                guard subsidiary.invitations.count == 1 else {
                    Logger(label: "CompanyManipulation").warning("Subsidiary has more than one invitations to this user")
                    continue
                }
                guard let subsidiaryId = subsidiary.id,
                let role = subsidiary.invitations.first?.role else { continue }
                let subsidiaryDTO = SubsidiaryResponseDTO(
                    id: subsidiaryId,
                    subsidiary_cic: subsidiary.subsidiaryCic,
                    name: subsidiary.name,
                    subsidiary_role: role
                )
                subsidiariesDTO.append(subsidiaryDTO)
            }
            guard !subsidiariesDTO.isEmpty else { continue }
            let companyDTO = CompanyResponseDTO(
                id: companyId,
                company_cic: company.companyCic,
                name: company.name,
                subdomain: company.subdomain,
                is_company_owner: company.user.userCic == userCic,
                subsidaries: subsidiariesDTO
            )
            companiesResponse.append(companyDTO)
        }
        return companiesResponse
    }
    func getUserCompaniesWithInvitations(userCic: String, on db: any Database) async throws -> [CompanyResponseDTO] {
        let workCompanies = try await getUserCompanies(userCic: userCic, on: db)
        let invitedCompanies = try await getUserInvitations(userCic: userCic, on: db)
        var mergedCompanies: [String: CompanyResponseDTO] = [:] // key = company_cic
        // 1️⃣ Primero, agregar todas las compañías donde trabaja el usuario
        for company in workCompanies {
            mergedCompanies[company.company_cic] = company
        }
        // 2️⃣ Luego, fusionar las invitaciones
        for invited in invitedCompanies {
            if let existing = mergedCompanies[invited.company_cic] {
                // Fusionar subsidiarias sin duplicados
                var combinedSubs = existing.subsidaries
                // Agregar solo subsidiarias nuevas
                let newSubs = invited.subsidaries.filter { invitedSub in
                    !existing.subsidaries.contains { $0.subsidiary_cic == invitedSub.subsidiary_cic }
                }
                combinedSubs.append(contentsOf: newSubs)
                let newCompanyResponseDTO = CompanyResponseDTO(
                    id: existing.id,
                    company_cic: existing.company_cic,
                    name: existing.name,
                    subdomain: existing.subdomain,
                    is_company_owner: existing.is_company_owner,
                    subsidaries: combinedSubs)
                mergedCompanies[invited.company_cic] = newCompanyResponseDTO
            } else {
                // Si la empresa solo está en invitaciones, agregarla completa
                mergedCompanies[invited.company_cic] = invited
            }
        }
        return Array(mergedCompanies.values)
    }
}
