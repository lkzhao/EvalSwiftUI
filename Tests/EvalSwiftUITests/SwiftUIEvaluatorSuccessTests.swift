import SwiftUI
import Testing
@testable import EvalSwiftUI

private struct DictionaryContext: SwiftUIEvaluatorContext {
    let values: [String: SwiftValue]

    func value(for identifier: String) -> SwiftValue? {
        values[identifier]
    }
}

private struct Badge: View {
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag")
                .imageScale(.small)
            Text(label)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.2))
        .clipShape(Capsule())
    }
}

private struct BadgeViewBuilder: SwiftUIViewBuilder {
    let name = "Badge"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let first = arguments.first, case let .string(label) = first.value else {
            throw SwiftUIEvaluatorError.invalidArguments("Badge expects a leading string label.")
        }

        return AnyView(Badge(label: label))
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

    @Test func rendersOptionalBinding() throws {
        let source = """
        VStack {
            let optionalGreeting: String? = "Hello"
            if let greeting = optionalGreeting {
                Text(greeting)
            }
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersOptionalBindingElseBranch() throws {
        let source = """
        VStack {
            let optionalGreeting: String? = nil
            if let greeting = optionalGreeting {
                Text(greeting)
            } else {
                Text("Fallback")
            }
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersOptionalBindingFromContext() throws {
        let source = """
        VStack {
            if let username = username {
                Text(username)
            }
        }
        """
        let context = DictionaryContext(values: ["username": .optional(.string("Morgan"))])
        _ = try evalSwiftUI(source, context: context)
    }

    @Test func rendersOptionalBindingShorthand() throws {
        let source = """
        VStack {
            let username: String? = "Taylor"
            if let username {
                Text(username)
            }
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersOptionalBindingShorthandFromContext() throws {
        let source = """
        VStack {
            if let username {
                Text(username)
            }
        }
        """
        let context = DictionaryContext(values: ["username": .optional(.string("Morgan"))])
        _ = try evalSwiftUI(source, context: context)
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

    @Test func rendersCustomViewUsingBuilder() throws {
        let source = """
        Badge("Beta")
        """

        let evaluator = SwiftUIEvaluator(viewBuilders: [BadgeViewBuilder()])
        _ = try evaluator.evaluate(source: source)
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

    @Test func supportsArrayBindings() throws {
        let source = """
        VStack {
            let labels = ["One", "Two"]
            Text("Done")
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func supportsRangeBindings() throws {
        let source = """
        VStack {
            let exclusives = 0..<3
            let inclusives = 1...3
            Text("Done")
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersForEachFromArray() throws {
        let source = """
        VStack {
            let users = ["Ava", "Ben"]
            ForEach(users) { user in
                Text(user)
            }
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersForEachFromRange() throws {
        let source = """
        VStack {
            ForEach(0..<3) { index in
                Text("Row \\(index)")
            }
        }
        """
        _ = try evalSwiftUI(source)
    }

    @Test func rendersForEachWithExplicitId() throws {
        let source = """
        VStack {
            let users = ["Ava", "Ben"]
            ForEach(users, id: \\.self) { user in
                Text(user)
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
