import Vapor
import Fluent

enum InvitationStatus: String, Codable {
    case pending
    case accepted
    case rejected
    case expired
    case revoked
}

final class Invitation: Model, @unchecked Sendable {
    static let schema = "invitations"

    @ID var id: UUID?
    //Relationships
    @Parent(key: "invited_by") var invitedBy: User
    @OptionalParent(key: "invited_user") var invitedUser: User?
    @Parent(key: "subsidiary") var subsidiary: Subsidiary
    //Atributes
    @Field(key: "email") var email: String
    @Field(key: "role") var role: UserSubsidiaryRole
    @Field(key: "status") var status: InvitationStatus
    @Field(key: "expired_at") var expiredAt: Date

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
    
    init(
        invitedByUserId: UUID,
        invitedUserId: UUID?,
        subsidiaryId: UUID,
        email: String,
        role: UserSubsidiaryRole,
        status: InvitationStatus,
        expiredAt: Date
    ) {
        self.$invitedBy.id = invitedByUserId
        self.$invitedUser.id = invitedUserId
        self.$subsidiary.id = subsidiaryId
        self.email = email
        self.role = role
        self.status = status
        self.expiredAt = expiredAt
    }
}

extension Invitation {
    static func findUnclaimedPendingInvitations(email: String, on db: any Database) async throws -> [Invitation] {
        try await Invitation.query(on: db)
            .filter(Invitation.self, \.$email == email)
            .filter(Invitation.self, \.$status == .pending)
            .filter(Invitation.self, \.$invitedUser.$id == nil)
            .all()
    }
    static func findPendingInvitations(userCic: String, on db: any Database) async throws -> [Invitation] {
        try await Invitation.query(on: db)
            .join(User.self, on: \Invitation.$invitedUser.$id == \User.$id)
            .filter(Invitation.self, \.$status == .pending)
            .filter(User.self, \.$userCic == userCic)
            .all()
    }
    static func findPendingInvitationsInSubsidiary(userCic: String, subsidiaryCic: String, on db: any Database) async throws -> Invitation? {
        try await Invitation.query(on: db)
            .join(Subsidiary.self, on: \Subsidiary.$company.$id == \Invitation.$id)
            .join(User.self, on: \Invitation.$invitedUser.$id == \User.$id)
            .filter(Invitation.self, \.$status == .pending)
            .filter(User.self, \.$userCic == userCic)
            .filter(Subsidiary.self, \.$subsidiaryCic == subsidiaryCic)
            .with(\.$invitedUser)
            .with(\.$subsidiary)
            .first()
    }
}
