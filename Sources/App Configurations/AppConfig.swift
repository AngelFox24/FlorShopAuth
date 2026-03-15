import Vapor

enum AppConfig {
    static let florShopWebBaseURL = Environment.get(EnvironmentVariables.florShopWebBaseURL.rawValue)!
}
