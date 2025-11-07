import Testing
@testable import EvalSwiftUI

@Test func example() async throws {
    let source = """
    Text("Hello, SwiftUI!")
    """
    let view = try evalSwiftUI(source)
}
