import Vapor

struct GoogleUser: Content, UserProviderIdentifiable {
    let id: String
    let email: String
    let name: String?
    let picture: String?
}

protocol UserProviderIdentifiable {
    var email: String { get }
}

struct GoogleToken: Content {
    let access_token: String
}

struct TestResponse: Content {
    let status: String
    let message: String
}
