import Foundation
import FlorShopDTOs
import FlorShopNetworking
import Vapor

actor ServiceTokenManager {
    static let shared = ServiceTokenManager()
    private var internalToken: InternalToken?
    func getToken(app: Application) async throws -> String {
        if let token = internalToken, !token.isExpired {
            return token.token
        }
        let newToken = try await fetchFromAuth(app: app)
        self.internalToken = newToken
        return newToken.token
    }
    private func fetchFromAuth(app: Application) async throws -> InternalToken {
        guard let service = try await InternalService.find(
            serviceName: AppConfig.internalServiceName,
            password: AppConfig.internalServicePassword,
            db: app.db
        ) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        let token = try await TokenService.generateInternalServiceToken(for: service, app: app)
        return InternalToken(token: token.serviceToken, expiry: token.expiry)
    }
}
