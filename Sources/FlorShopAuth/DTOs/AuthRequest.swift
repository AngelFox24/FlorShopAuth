import Vapor

struct AuthRequest: Content {
    let token: String
    let provider: AuthProvider
}
