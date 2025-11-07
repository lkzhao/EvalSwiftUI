import Testing
@testable import EvalSwiftUI

struct SwiftUIEvaluatorSuccessTests {
    @Test func rendersTextLiteral() throws {
        let source = """
        Text("Hello, SwiftUI!")
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersTextWithModifiers() throws {
        let source = """
        Text("Hello, SwiftUI!")
            .font(.title)
            .padding()
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersVStackWithChildText() throws {
        let source = """
        VStack {
            Text("Hello, SwiftUI!")
                .font(.title)
                .padding()
        }
        """
        _ = try evalSwiftUI(source)
    }
}
