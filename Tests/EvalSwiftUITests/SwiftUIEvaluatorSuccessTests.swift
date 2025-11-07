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

    @Test func rendersImageWithModifiers() throws {
        let source = """
        Image(systemName: "globe")
            .imageScale(.large)
            .foregroundStyle(.tint)
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersNestedStacks() throws {
        let source = """
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                Text("Left")
                Text("Right")
            }
            Text("Bottom")
        }
        """
        _ = try evalSwiftUI(source)
    }
}
