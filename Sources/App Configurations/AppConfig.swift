import Vapor

enum AppConfig {
    static let florShopWebBaseURL = Environment.get(EnvironmentVariables.florShopWebBaseURL.rawValue)!
    static let florShopBillingApiURL = Environment.get(EnvironmentVariables.florShopBillingApiURL.rawValue)!
    static let internalServiceName = Environment.get(EnvironmentVariables.internalServiceName.rawValue)!
    static let internalServicePassword = Environment.get(EnvironmentVariables.internalServicePassword.rawValue)!
}
