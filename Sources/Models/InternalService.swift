import Vapor
import Fluent
import JWT

final class InternalService: Model, @unchecked Sendable {
    static let schema = "internal_services"

    @ID var id: UUID?
    
    @Field(key: "service_name") var serviceName: String
    @Field(key: "secret_hash") var secretHash: String
    @Field(key: "is_active") var isActive: Bool
    
    @Field(key: "scopes") var scopes: [String]
    
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        serviceName: String,
        secretHash: String,
        isActive: Bool = true,
        scopes: [String] = []
    ) {
        self.serviceName = serviceName
        self.secretHash = secretHash
        self.isActive = isActive
        self.scopes = scopes
    }
}

extension InternalService {
    static func find(serviceName: String, password: String, db: any Database) async throws -> Self? {
        guard let service = try await Self.query(on: db)
            .filter(InternalService.self, \.$serviceName == serviceName)
            .filter(InternalService.self, \.$isActive == true)
            .first()
        else {
            return nil
        }

        let isValid = try Bcrypt.verify(password, created: service.secretHash)
        return isValid ? service : nil
    }
}
