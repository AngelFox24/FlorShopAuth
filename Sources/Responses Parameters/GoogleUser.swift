import Vapor

struct GoogleUser: Content {
    let id: String
    let email: String
    let name: String?
    let picture: String?
}
