import Vapor

extension Application {
    func getHostname() -> String {
        switch self.environment {
        case .production:
            return "localhost"//Server Ubuntu in docker container
        default://develop
            return "192.168.2.5"//Xcode
        }
    }
}
