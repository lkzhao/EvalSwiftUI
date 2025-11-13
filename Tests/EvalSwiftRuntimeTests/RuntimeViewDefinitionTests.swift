import SwiftUI
import Testing
@testable import EvalSwiftRuntime
import EvalSwiftIR

struct RuntimeViewDefinitionTests {
    @Test func instantiatesViewBodyReturnsRuntimeView() throws {
        let source = """
        struct SampleView: View {
            var title: String = "Hello"

            var body: some View {
                Text(title)
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "SampleView")
        let rendered = try instantiateView(type: type)

        guard case .view(let runtimeView) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(runtimeView.typeName == "Text")
    }

    @Test func implicitReturnUsesLastExpression() throws {
        let source = """
        struct ImplicitView: View {
            var title: String = "Implicit"

            var body: some View {
                Text("Ignored")
                Text(title)
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "ImplicitView")
        let rendered = try instantiateView(type: type)

        guard case .view(let runtimeView) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(runtimeView.typeName == "Text")
    }

    @Test func textExpressionProducesRuntimeView() throws {
        let source = """
        struct TextView: View {
            var body: some View {
                Text("Hello")
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "TextView")
        let rendered = try instantiateView(type: type)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected view result, got \(rendered)")
        }

        #expect(view.typeName == "Text")
    }

    @Test func vStackCollectsChildTextViews() throws {
        let source = """
        struct StackView: View {
            var body: some View {
                VStack {
                    Text("First")
                    Text("Second")
                }
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "StackView")
        let rendered = try instantiateView(type: type)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected view result, got \(rendered)")
        }

        #expect(view.typeName == "VStack")
    }

    @Test func vStackHonorsSpacingArgument() throws {
        let source = """
        struct StackSpacingView: View {
            var body: some View {
                VStack(spacing: 12) {
                    Text("Only Child")
                }
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "StackSpacingView")
        let rendered = try instantiateView(type: type)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected view result, got \(rendered)")
        }

        #expect(view.typeName == "VStack")
    }

    @Test func argumentsPopulateStoredBindingsWithoutDefaults() throws {
        let source = """
        struct RequiredArgumentView: View {
            var title: String

            var body: some View {
                Text(title)
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "RequiredArgumentView")
        let arguments = [RuntimeArgument(label: "title", value: .string("Runtime"))]
        let rendered = try instantiateView(type: type, arguments: arguments)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(view.arguments.first?.value.asString == "Runtime")
    }

    @Test func argumentsOverrideDefaultBindingValues() throws {
        let source = """
        struct OverrideView: View {
            var title: String = "Default"

            var body: some View {
                Text(title)
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "OverrideView")
        let arguments = [RuntimeArgument(label: "title", value: .string("Injected"))]
        let rendered = try instantiateView(type: type, arguments: arguments)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(view.arguments.first?.value.asString == "Injected")
    }

    @Test func explicitInitializerAssignsStoredProperties() throws {
        let source = """
        struct ExplicitInitView: View {
            var title: String

            init(title: String) {
                self.title = title
            }

            var body: some View {
                Text(title)
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "ExplicitInitView")
        let arguments = [RuntimeArgument(label: "title", value: .string("Initializer"))]
        let rendered = try instantiateView(type: type, arguments: arguments)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(view.arguments.first?.value.asString == "Initializer")
    }

    @Test func scopeAssignments() throws {
        let source = """
        struct ShadowedInitView: View {
            var title: String

            init() {
                var title = "Local"
                title = "Next"
                self.title = title
                title = "Final"
            }

            var body: some View {
                Text(title)
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "ShadowedInitView")
        let rendered = try instantiateView(type: type)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(view.arguments.first?.value.asString == "Next")
    }

    @Test func selfMemberReadsStoredProperty() throws {
        let source = """
        struct SelfReadView: View {
            var title: String

            init(title: String) {
                self.title = title
                var title = "Local"
                let current = self.title
                self.title = "Changed"
                self.title = current
            }

            var body: some View {
                Text(title)
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "SelfReadView")
        let arguments = [RuntimeArgument(label: "title", value: .string("Value"))]
        let rendered = try instantiateView(type: type, arguments: arguments)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(view.arguments.first?.value.asString == "Value")
    }

    @Test func synthesizedInitializerProvidesDefaultValues() throws {
        let source = """
        struct SynthesizedInitView: View {
            var title: String = "Synthed"

            var body: some View {
                Text(title)
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "SynthesizedInitView")
        let rendered = try instantiateView(type: type)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(view.arguments.first?.value.asString == "Synthed")
    }

    @Test func nestedViewDefinition() throws {
        let source = """
        struct OuterView: View {
            struct InnerView: View {
                var title: String = "Inner"
        
                var body: some View {
                    Text(title)
                }
            }
        
            var body: some View {
                InnerView()
            }
        }
        """

        let module = RuntimeModule(source: source)
        let outerType = try module.type(named: "OuterView")
        let outerInstance = try outerType.makeInstance()
        let outerRendererd = try outerInstance.callFunction("body")!

        guard case .view(let outerViewContent) = outerRendererd else {
            throw TestFailure.expected("Expected runtime view result, got \(outerRendererd)")
        }

        #expect(outerViewContent.typeName == "InnerView")
        let innerType = try outerInstance.type(named: "InnerView")
        let innerInstance = try innerType.makeInstance()
        let innerRendererd = try innerInstance.callFunction("body")!

        guard case .view(let innerViewContent) = innerRendererd else {
            throw TestFailure.expected("Expected runtime view result, got \(innerRendererd)")
        }
        #expect(innerViewContent.typeName == "Text")
        #expect(innerViewContent.arguments.first?.value.asString == "Inner")
    }

    @MainActor
    @Test func stateMutationTriggersViewRerender() throws {
        let source = """
        struct CounterView: View {
            var count: Int = 0

            var body: some View {
                Text("Count: \\(count)")
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "CounterView")
        let renderer = try RuntimeViewRenderer(type: type)

        try assertViewMatch(renderer.renderedView, Text("Count: 0"))

        try renderer.instance.set("count", value: .int(5))

        try assertViewMatch(renderer.renderedView, Text("Count: 5"))
    }

    // MARK: - Helpers

    private func instantiateView(
        type: RuntimeType,
        arguments: [RuntimeArgument] = [],
    ) throws -> RuntimeValue {
        let instance = try type.makeInstance(arguments: arguments)
        return try instance.callFunction("body")!
    }
}
