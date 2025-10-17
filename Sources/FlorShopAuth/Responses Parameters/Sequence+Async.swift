import Foundation

extension Sequence {
    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var result: [T] = []
        for element in self {
            if let value = try await transform(element) {
                result.append(value)
            }
        }
        return result
    }
}
