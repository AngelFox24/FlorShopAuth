import Vapor

actor AuthProviderManager {
    private let providers: [any AuthProviderProtocol]

    init(providers: [any AuthProviderProtocol]) {
        self.providers = providers
    }
}

extension AuthProviderManager {
    func verifyToken(
        _ token: String,
        using providerType: AuthProvider,
        on req: Request
    ) async throws -> UserIdentityDTO {
        guard let provider = providers.first(where: { $0.name == providerType }) else {
            throw Abort(.badRequest, reason: "Unsupported provider \(providerType)")
        }
        return try await provider.verifyToken(token, req: req)
    }
}
