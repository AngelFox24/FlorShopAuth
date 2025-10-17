import Fluent
import Vapor

func routes(_ app: Application) throws {
    let authProviderManager = AuthProviderManager(providers: [GoogleAuthProvider()])
    try app.register(collection: TestEndpoint())
    try app.register(collection: AuthController(authProviderManager: authProviderManager))
    try app.register(collection: GoogleAuthController())
    try app.register(collection: SelectionCompanyController())
    try app.register(collection: RefreshTokenController())
}
