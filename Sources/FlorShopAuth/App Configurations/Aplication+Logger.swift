import Vapor

extension Application {
    func configLogger() throws {
        guard let logLevelString = Environment.get(EnvironmentVariables.logLevel.rawValue) else {
            fatalError("\(EnvironmentVariables.logLevel.rawValue) don't set in .env.\(self.environment.name)")
        }
        guard let level = Logger.Level(rawValue: logLevelString.lowercased()) else {
            fatalError("must set a valid \(EnvironmentVariables.logLevel.rawValue) in .env.\(self.environment.name)")
        }
        self.logger.logLevel = level
    }
}
