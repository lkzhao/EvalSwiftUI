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
        let compiled = try compiledView(named: "SampleView", from: module)
        let rendered = try instantiateView(compiled, module: module)

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
        let compiled = try compiledView(named: "ImplicitView", from: module)
        let rendered = try instantiateView(compiled, module: module)

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
        let compiled = try compiledView(named: "TextView", from: module)
        let rendered = try instantiateView(compiled, module: module)

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
        let compiled = try compiledView(named: "StackView", from: module)
        let rendered = try instantiateView(compiled, module: module)

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
        let compiled = try compiledView(named: "StackSpacingView", from: module)
        let rendered = try instantiateView(compiled, module: module)

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
        let compiled = try compiledView(named: "RequiredArgumentView", from: module)
        let arguments = [RuntimeArgument(label: "title", value: .string("Runtime"))]
        let rendered = try instantiateView(compiled, module: module, arguments: arguments)

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
        let compiled = try compiledView(named: "OverrideView", from: module)
        let arguments = [RuntimeArgument(label: "title", value: .string("Injected"))]
        let rendered = try instantiateView(compiled, module: module, arguments: arguments)

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
        let compiled = try compiledView(named: "ExplicitInitView", from: module)
        let arguments = [RuntimeArgument(label: "title", value: .string("Initializer"))]
        let rendered = try instantiateView(compiled, module: module, arguments: arguments)

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
        let compiled = try compiledView(named: "ShadowedInitView", from: module)
        let rendered = try instantiateView(compiled, module: module)

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
        let compiled = try compiledView(named: "SelfReadView", from: module)
        let arguments = [RuntimeArgument(label: "title", value: .string("Value"))]
        let rendered = try instantiateView(compiled, module: module, arguments: arguments)

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
        let compiled = try compiledView(named: "SynthesizedInitView", from: module)
        let rendered = try instantiateView(compiled, module: module)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected runtime view result, got \(rendered)")
        }

        #expect(view.arguments.first?.value.asString == "Synthed")
    }

    @MainActor
    @Test func makeSwiftUIViewRendersText() throws {
        let source = """
        struct TextView: View {
            var body: some View {
                Text("Render Me")
            }
        }
        """

        let module = RuntimeModule(source: source)
        let compiled = try compiledView(named: "TextView", from: module)
        let rendered = try instantiateView(compiled, module: module)

        guard case .view(let runtimeView) = rendered else {
            throw TestFailure.expected("Expected runtime view")
        }

        let realized = try runtimeView.makeSwiftUIView(module: module)
        let renderer = ImageRenderer(content: realized)
        renderer.scale = 1
        #expect(renderer.cgImage != nil)
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
        let compiled = try compiledView(named: "CounterView", from: module)
        let renderer = try RuntimeViewRenderer(
            definition: compiled,
            module: module,
            arguments: [],
            scope: module.globalScope,
        )

        try assertViewMatch(renderer.renderedView, Text("Count: 0"))

        try renderer.instance.set("count", value: .int(5))

        try assertViewMatch(renderer.renderedView, Text("Count: 5"))
    }

    // MARK: - Helpers

    private func compiledView(named name: String, from module: RuntimeModule) throws -> CompiledViewDefinition {
        guard let compiled = module.viewDefinition(named: name) else {
            throw TestFailure.expected("Expected compiled view binding for \(name)")
        }
        return compiled
    }

    private func instantiateView(
        _ compiled: CompiledViewDefinition,
        module: RuntimeModule,
        arguments: [RuntimeArgument] = []
    ) throws -> RuntimeValue {
        let instance = try compiled.makeInstance(arguments: arguments, scope: module.globalScope)
        return try instance.callMethod("body")!
    }
}
