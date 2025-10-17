import Foundation
import Vapor

struct RegisterRequest: Content {
    let user: User
    let userIdentity: UserIdentity
    let company: Company
}
