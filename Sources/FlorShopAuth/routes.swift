import Fluent
import Vapor

func routes(_ app: Application) throws {
    let authProviderManager = AuthProviderManager(providers: [GoogleAuthProvider()])
    let userManipulation = UserManipulation()
    let companyManipulation = CompanyManipulation()
    try app.register(collection: TestEndpoint())
    try app.register(collection: AuthController(authProviderManager: authProviderManager, userManipulation: userManipulation))
    try app.register(collection: CompanyController(
        authProviderManager: authProviderManager,
        userManipulation: userManipulation,
        companyManipulation: companyManipulation))
}
