import Testing
@testable import EvalSwiftUI

private struct DictionaryContext: SwiftUIEvaluatorContext {
    let values: [String: SwiftValue]

    func value(for identifier: String) -> SwiftValue? {
        values[identifier]
    }
}

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

    @Test func rendersTextWithStringInterpolation() throws {
        let source = """
        VStack {
            let name = "Taylor"
            Text("Hello \\(name)")
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersTextUsingExternalContext() throws {
        let source = """
        Text("Welcome \\(username)")
        """
        let context = DictionaryContext(values: ["username": .string("Morgan")])
        _ = try evalSwiftUI(source, context: context)
    }

    @Test func rendersTextWithBooleanInterpolation() throws {
        let source = """
        VStack {
            let isEnabled = true
            Text("Enabled: \\(isEnabled)")
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersTextUsingBooleanContext() throws {
        let source = """
        Text("Flag: \\(isEnabled)")
        """
        let context = DictionaryContext(values: ["isEnabled": .bool(true)])
        _ = try evalSwiftUI(source, context: context)
    }

    @Test func rendersConditionalContent() throws {
        let source = """
        VStack {
            let showGreeting = true
            if showGreeting {
                Text("Hello")
            }
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersConditionalElseBranches() throws {
        let source = """
        VStack {
            let showPrimary = false
            let showSecondary = true
            if showPrimary {
                Text("Primary")
            } else if showSecondary {
                Text("Secondary")
            } else {
                Text("Fallback")
            }
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func supportsLetBindingsInsideClosures() throws {
        let source = """
        VStack {
            let value = "scoped"
            Text(value)
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func propagatesBindingsToNestedClosures() throws {
        let source = """
        VStack {
            let label = "outer"
            HStack {
                Text(label)
            }
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersAdvancedModifiers() throws {
        let source = """
        Text("Styled")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(4)
            .foregroundStyle(.red)
            .frame(width: 120, height: 60, alignment: .leading)
            .frame(minWidth: 60, maxWidth: .infinity, alignment: .center)
        """
        _ = try evalSwiftUI(source)
    }
}
