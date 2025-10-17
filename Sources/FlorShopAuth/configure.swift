import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.http.server.configuration.hostname = app.getHostname()
    app.http.server.configuration.port = 8081
    app.databases.use(try app.getFactory(), as: app.getDatabaseID())
    try await app.setSignature()
    app.migrations.add(CreateUser())
    app.migrations.add(CreateCompany())
    app.migrations.add(CreateSubsidiary())
    app.migrations.add(CreateUserSubsidiary())
    app.migrations.add(CreateUserIdentity())
    app.migrations.add(CreateRefreshToken())
    //Espera a que la migracion se haga
    try await app.autoMigrate()

    // register routes
    try routes(app)
}
