import Vapor
import Fluent
import FlorShopDTOs

struct UserManipulation {
    func asociateUser(provider: AuthProvider, userIdentityDTO: UserIdentityDTO, on db: any Database) async throws -> User? {
        guard let userIdentity = try await UserIdentity.findUserIdentityForAddOtherProvider(email: userIdentityDTO.email, provider: provider, on: db),
              let userId = userIdentity.user.id else {
            return nil
        }
        //Asociate new user identity
        let newUserIdentity = UserIdentity(
            userId: userId,
            provider: provider,
            providerId: userIdentityDTO.providerId,
            email: userIdentityDTO.email
        )
        try await newUserIdentity.save(on: db)
        return userIdentity.user
    }
    func saveUser(provider: AuthProvider, userIdentityDTO: UserIdentityDTO, on db: any Database) async throws -> User {
        let userToSave: User
        if let userFound = try await User.findUser(email: userIdentityDTO.email, provider: provider, on: db) {
            return userFound
        } else if let user = try await asociateUser(
            provider: provider,
            userIdentityDTO: userIdentityDTO,
            on: db
        ) {//existe usuario
            userToSave = user
        } else {//nuevo usuario
            let newUserCic = UUID().uuidString
            let newUser = User(
                userCic: newUserCic
            )
            try await newUser.save(on: db)
            guard let userId = newUser.id else {
                throw Abort(.internalServerError, reason: "userId not created for new user")
            }
            let newUserIdentity = UserIdentity(
                userId: userId,
                provider: provider,
                providerId: userIdentityDTO.providerId,
                email: userIdentityDTO.email
            )
            try await newUserIdentity.save(on: db)
            userToSave = newUser
        }
        return userToSave
    }
    func asociateInvitationIfExist(provider: AuthProvider, userIdentityDTO: UserIdentityDTO, on db: any Database) async throws {
        let invitations = try await Invitation.findUnclaimedPendingInvitations(email: userIdentityDTO.email, on: db)
        guard !invitations.isEmpty else {//Hay invitaciones pendientes sin asignar
            return
        }
        //Creamos el usuario porque ya ha sido invitado
        let user = try await saveUser(provider: provider, userIdentityDTO: userIdentityDTO, on: db)
        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "No se pudo obtener el ID del usuario recién creado")
        }
        for invitation in invitations {
            invitation.$invitedUser.id = userId
            try await invitation.save(on: db)
        }
    }
}
