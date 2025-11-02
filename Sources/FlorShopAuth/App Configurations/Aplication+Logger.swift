import Vapor

extension Application {
    func configLogger() {
        if let logLevelString = Environment.get("LOG_LEVEL"),
           let level = Logger.Level(rawValue: logLevelString.lowercased()) {
            self.logger.logLevel = level
        } else {
            self.logger.logLevel = self.environment == .development ? .debug : .info
        }
    }
}
