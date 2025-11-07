import Testing
@testable import EvalSwiftUI

@Test func example() async throws {
    let source = """
    Text("Hello, SwiftUI!")
    """
    _ = try evalSwiftUI(source)
}

@Test func textWithFontAndPadding() async throws {
    let source = """
    Text("Hello, SwiftUI!")
        .font(.title)
        .padding()
    """
    _ = try evalSwiftUI(source)
}
