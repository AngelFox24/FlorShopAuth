import Vapor

struct TestEndpoint: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("test")
        auth.get(use: testEnpoint)
    }
    
    @Sendable
    func testEnpoint(req: Request) throws -> Response {
        return Response(status: .ok)
    }
}
