import NIOConcurrencyHelpers
import Vapor
import JWT
import FlorShopAuthClient

extension Request.JWT {
    public var selfflorshop: SelfFlorShopAuth {
        .init(_jwt: self)
    }

    public struct SelfFlorShopAuth: Sendable {
        public let _jwt: Request.JWT

        public func verify() async throws -> FlorShopAuthClient.InternalServiceTokenPayload {
            guard let token = _jwt._request.headers.bearerAuthorization?.token else {
                throw Abort(.unauthorized)
            }

            return try await verify(token)
        }

        public func verify(_ token: String) async throws -> FlorShopAuthClient.InternalServiceTokenPayload {
            let payload = try await _jwt._request.application.jwt.keys.verify(
                token,
                as: FlorShopAuthClient.InternalServiceTokenPayload.self
            )

            return payload
        }

        public func verifyBaseToken() async throws -> FlorShopAuthClient.BaseTokenPayload {
            guard let token = _jwt._request.headers.bearerAuthorization?.token else {
                throw Abort(.unauthorized)
            }
            
            return try await verifyBaseToken(token)
        }

        public func verifyBaseToken(_ token: String) async throws -> FlorShopAuthClient.BaseTokenPayload {
            let payload = try await _jwt._request.application.jwt.keys.verify(
                token,
                as: FlorShopAuthClient.BaseTokenPayload.self
            )

            return payload
        }

        public func verifyScopedToken() async throws -> FlorShopAuthClient.ScopedTokenPayload {
            guard let token = _jwt._request.headers.bearerAuthorization?.token else {
                throw Abort(.unauthorized)
            }
            
            return try await verifyScopedToken(token)
        }

        public func verifyScopedToken(_ token: String) async throws -> FlorShopAuthClient.ScopedTokenPayload {
            let payload = try await _jwt._request.application.jwt.keys.verify(
                token,
                as: FlorShopAuthClient.ScopedTokenPayload.self
            )

            return payload
        }
    }
}
