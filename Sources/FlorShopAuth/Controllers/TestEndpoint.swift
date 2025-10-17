import Fluent
import Vapor

struct TestEndpoint: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("test")
        auth.get(use: testEnpoint)
    }
    
    struct TestResponse: Content {
        let result: String
    }
    @Sendable
    func testEnpoint(req: Request) throws -> TestResponse {
        return TestResponse(result: "OK")
    }
}
