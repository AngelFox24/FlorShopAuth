import Vapor

struct AuthRequest: Content {
    let provider: AuthProvider
}
