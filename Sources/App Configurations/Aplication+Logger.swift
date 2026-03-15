import Vapor

extension Application {
    func configLogger() {
        guard let level = Logger.Level(rawValue: Environment.get(EnvironmentVariables.logLevel.rawValue)!.lowercased()) else {
            fatalError("must set a valid \(EnvironmentVariables.logLevel.rawValue) in .env.\(self.environment.name)")
        }
        self.logger.logLevel = level
    }
}
