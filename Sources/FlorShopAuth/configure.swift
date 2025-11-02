import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = app.getHostname()
    app.http.server.configuration.port = 8081
    app.configLogger()
    app.databases.use(try app.getFactory(), as: app.getDatabaseID())
    try await app.setSignature()
    try await app.setVendorVerficationIdentifiers()
    app.migrations.add(CreateUser())
    app.migrations.add(CreateCompany())
    app.migrations.add(CreateSubsidiary())
    app.migrations.add(CreateInvitation())
    app.migrations.add(CreateUserSubsidiary())
    app.migrations.add(CreateUserIdentity())
    app.migrations.add(CreateRefreshToken())
    //Espera a que la migracion se haga
    try await app.autoMigrate()
    
    try routes(app)
}
