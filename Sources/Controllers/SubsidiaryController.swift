import Vapor
import FlorShopDTOs

struct SubsidiaryController: RouteCollection {
    let authProviderManager: AuthProviderManager
    let userManipulation: UserManipulation
    let companyManipulation: CompanyManipulation
    func boot(routes: any RoutesBuilder) throws {
        let subsidiary = routes.grouped("subsidiary")
        subsidiary.get(use: getUserSubsidiaries)
        subsidiary.post(use: saveSubsidiary)
        let selecction = subsidiary.grouped("selection")
        selecction.get(use: selectSubsidiary)
//        let register = subsidiary.grouped("register")
//        register.post(use: registerSubsidiary)
        let userSubsidiary = routes.grouped("usersubsidiary")
        userSubsidiary.post(use: updateUserSubsidiary)
        let initalData = routes.grouped("initialData")
        initalData.get(use: getInitialData)
    }
    
    //Get: subsidiary?companyCic=89fsa78978as78ga789
    @Sendable
    func getUserSubsidiaries(_ req: Request) async throws -> [SubsidiaryResponseDTO] {
        guard let companyCic = try? req.query.get(String.self, at: "companyCic") else {
            throw Abort(.badRequest, reason: "Must specify a subsidiary id")
        }
        let payload = try await req.jwt.verify(as: BaseTokenPayload.self)
        let subsidiaries: [SubsidiaryResponseDTO] = try await companyManipulation.getUserSubsidiariesWithInvitations(
            userCic: payload.sub.value,
            companyCic: companyCic,
            on: req.db
        )
        return subsidiaries
    }
    //Get: subsidiary/selection?cic=89fsa78978as78ga789
    @Sendable
    func selectSubsidiary(req: Request) async throws -> ScopedTokenWithRefreshResponse {
        guard let subsidiaryCic = try? req.query.get(String.self, at: "cic") else {
            throw Abort(.badRequest, reason: "Must specify a subsidiary id")
        }
        // Obtener el usuario autenticado del JWT
        let payload = try await req.jwt.verify(as: BaseTokenPayload.self)
        let userCic = payload.sub.value
        //TODO: Select Company and Subsidiary
        let userSubsidiary: UserSubsidiary
        if let workUserSubsidiary = try await UserSubsidiary.getSubsidiaryWhereUserWorks(
            userCic: userCic,
            subsidiaryCic: subsidiaryCic,
            on: req.db
        ) {
            userSubsidiary = workUserSubsidiary
        } else {//Buscamos en la tabla de invitados
            guard let invitation = try await Invitation.findPendingInvitationsInSubsidiary(
                userCic: userCic,
                subsidiaryCic: subsidiaryCic,
                on: req.db
            ) else {
                throw Abort(.badRequest, reason: "user not found in this subsidiary")
            }
            guard let userId = invitation.invitedUser?.id else {
                throw Abort(.internalServerError, reason: "user id not found")
            }
            guard let subsidiaryId = invitation.subsidiary.id else {
                throw Abort(.internalServerError, reason: "subsidiary id not found")
            }
            let newUserSubsidiary = UserSubsidiary(
                userId: userId,
                subsidiaryId: subsidiaryId,
                role: invitation.role,
                status: .active
            )
            invitation.status = .accepted
            try await newUserSubsidiary.save(on: req.db)
            try await invitation.save(on: req.db)
            userSubsidiary = newUserSubsidiary
        }
        //TODO: Cuando selecciona una subsidiaria donde aun no se ha registrado, entonces hay que registrarlo
        let tokenString = try await TokenService.generateScopedToken(userSubsidiary: userSubsidiary, req: req)
        let refreshScopedToken = try await TokenService.getRefreshScopedToken(userSubsidiary: userSubsidiary, req: req)//Buuuuug si vencio el refresh token se malogra todo
        return ScopedTokenWithRefreshResponse(scopedToken: tokenString, refreshScopedToken: refreshScopedToken)
    }
    //POST: subsidiary
    @Sendable
    func saveSubsidiary(_ req: Request) async throws -> DefaultResponse {
        let payload = try await req.jwt.verify(as: InternalPayload.self)
        let registerDTO = try req.content.decode(RegisterSubsidiaryRequest.self)
        
        let userCic = payload.sub.value
        try await req.db.transaction { transaction in
            if let subsidiaryCic = registerDTO.subsidiary.subsidiaryCic {//Enviar el subsidiaryCic tiene la intencion de actualizar
                //Update
                guard let subsidiary = try await Subsidiary.findSubsidiary(subsidiaryCic: subsidiaryCic, on: req.db) else {
                    throw Abort(.badRequest, reason: "Subsidiary no encontrado para actualizar")
                }
                guard try await Subsidiary.subsidiaryNameExist(name: registerDTO.subsidiary.name, on: req.db) else {
                    throw Abort(.badRequest, reason: "Subsidiary name already exist")
                }
                subsidiary.name = registerDTO.subsidiary.name
                try await subsidiary.save(on: req.db)
            } else {//Create
                guard let user: User = try await User.findUser(userCic: userCic, on: transaction),
                      let userId = user.id else {
                    throw Abort(.internalServerError, reason: "Failed to find user")
                }
                guard let company = try await Company.findCompany(companyCic: payload.companyCic, on: transaction),
                      let companyId = company.id else {
                    throw Abort(.internalServerError, reason: "Failed to find company")
                }
                let newSubsidiary = try await companyManipulation.saveSubsidiary(
                    name: registerDTO.subsidiary.name,
                    companyId: companyId,
                    on: transaction
                )
                guard let subsidiaryId = newSubsidiary.id else {
                    throw Abort(.internalServerError, reason: "Failed to generate id for new subsidiary")
                }
                let _ = try await companyManipulation.asingUserToSubsidiary(
                    userId: userId,
                    subsidiaryId: subsidiaryId,
                    role: registerDTO.role,
                    on: transaction
                )
            }
        }
        return DefaultResponse()
    }
    //POST: usersubsidiary
    @Sendable
    func updateUserSubsidiary(_ req: Request) async throws -> DefaultResponse {
        let payload = try await req.jwt.verify(as: InternalPayload.self)
        let updateRequest = try req.content.decode(UpdateUserSubsidiaryRequest.self)
        //TODO: Validar si el payload.sub.value (employeeCic) tiene suficientes privilegios para cambiar privilegios a otros
        guard let userSubsidiary = try await UserSubsidiary.getSubsidiaryWhereUserWorks(
            userCic: updateRequest.employeeCic,
            subsidiaryCic: payload.subsidiaryCic,
            on: req.db
        ) else {
            throw Abort(.badRequest, reason: "UserSubsidiary don't exist")
        }
        userSubsidiary.role = updateRequest.role
        userSubsidiary.status = updateRequest.status
        try await userSubsidiary.save(on: req.db)
        return DefaultResponse()
    }
    //GET: initialData?subsidiaryCic=8sfa8978fsa09fa0fsa
    @Sendable
    func getInitialData(_ req: Request) async throws -> InitialDataDTO {
        guard let subsidiaryCic = try? req.query.get(String.self, at: "subsidiaryCic") else {
            throw Abort(.badRequest, reason: "Must specify a subsidiaryCic")
        }
        guard let subsidiaryEntity = try await Subsidiary.findSubsidiary(subsidiaryCic: subsidiaryCic, on: req.db) else {
            throw Abort(.badRequest, reason: "Subsidiary don't exist for this subsidiaryCic")
        }
        try await subsidiaryEntity.$company.load(on: req.db)
        let companyEntity = subsidiaryEntity.company
        return InitialDataDTO(
            company: .init(
                companyCic: companyEntity.companyCic,
                companyName: companyEntity.name,
                ruc: "",
                createdAt: companyEntity.createdAt ?? Date(),
                updatedAt: companyEntity.updatedAt ?? Date()
            ),
            subsidiary: .init(
                subsidiaryCic: subsidiaryEntity.subsidiaryCic,
                name: subsidiaryEntity.name,
                companyCic: companyEntity.companyCic,
                imageUrl: nil,
                createdAt: subsidiaryEntity.createdAt ?? Date(),
                updatedAt: subsidiaryEntity.updatedAt ?? Date()
            )
        )
    }
}
