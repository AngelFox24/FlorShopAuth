import Vapor

extension Application {
    func addCorsMiddleware() {
        let corsConfig = CORSMiddleware(
            configuration: CORSMiddleware.Configuration(
                allowedOrigin: .custom(Environment.get(EnvironmentVariables.florShopWebBaseURL.rawValue)!),
                allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE],
                allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
            )
        )
        self.middleware.use(corsConfig)
    }
}
