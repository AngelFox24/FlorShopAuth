import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = app.getHostname()
    app.http.server.configuration.port = app.getPort()
    app.configLogger()
    app.setJsonDecoder()
    app.databases.use(app.getFactory(), as: app.getDatabaseID())
    try await app.setSignature()
    app.setVendorVerficationIdentifiers()
    app.addCorsMiddleware()
    app.configureMigrations()
    //Espera a que la migracion se haga
    try await app.autoMigrate()
    try routes(app)
}
