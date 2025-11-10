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

        let module = makeModule(source: source)
        registerDefaultBuilders(on: module)
        let compiled = try compiledView(named: "SampleView", from: module)
        let rendered = try compiled.instantiate(scope: module.globalScope)

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

        let module = makeModule(source: source)
        registerDefaultBuilders(on: module)
        let compiled = try compiledView(named: "ImplicitView", from: module)
        let rendered = try compiled.instantiate(scope: module.globalScope)

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

        let module = makeModule(source: source)
        registerDefaultBuilders(on: module)
        let compiled = try compiledView(named: "TextView", from: module)
        let rendered = try compiled.instantiate(scope: module.globalScope)

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

        let module = makeModule(source: source)
        registerDefaultBuilders(on: module)
        let compiled = try compiledView(named: "StackView", from: module)
        let rendered = try compiled.instantiate(scope: module.globalScope)

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

        let module = makeModule(source: source)
        registerDefaultBuilders(on: module)
        let compiled = try compiledView(named: "StackSpacingView", from: module)
        let rendered = try compiled.instantiate(scope: module.globalScope)

        guard case .view(let view) = rendered else {
            throw TestFailure.expected("Expected view result, got \(rendered)")
        }

        #expect(view.typeName == "VStack")
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

        let module = makeModule(source: source)
        registerDefaultBuilders(on: module)
        let compiled = try compiledView(named: "TextView", from: module)
        let rendered = try compiled.instantiate(scope: module.globalScope)

        guard case .view(let runtimeView) = rendered else {
            throw TestFailure.expected("Expected runtime view")
        }

        let realized = try module.makeSwiftUIView(typeName: runtimeView.typeName, parameters: runtimeView.parameters, scope: module.globalScope)
        let renderer = ImageRenderer(content: realized)
        renderer.scale = 1
        #expect(renderer.cgImage != nil)
    }

    // MARK: - Helpers

    private func makeModule(source: String) -> RuntimeModule {
        let parser = SwiftIRParser()
        let ir = parser.parseModule(source: source)
        return RuntimeModule(ir: ir)
    }

    private func compiledView(named name: String, from module: RuntimeModule) throws -> CompiledViewDefinition {
        guard let value = module.value(for: name),
              case .viewDefinition(let compiled) = value else {
            throw TestFailure.expected("Expected compiled view binding for \(name)")
        }
        return compiled
    }

    private func registerDefaultBuilders(on module: RuntimeModule) {
        module.registerViewBuilder(TextRuntimeViewBuilder())
        module.registerViewBuilder(VStackRuntimeViewBuilder())
    }
}

private struct TextRuntimeViewBuilder: RuntimeViewBuilder {
    let typeName = "Text"

    func makeSwiftUIView(parameters: [RuntimeParameter], module: RuntimeModule, scope: RuntimeScope) throws -> AnyView {
        guard let first = parameters.first, let string = first.value.asString else {
            throw RuntimeError.invalidViewArgument("Text expects a string parameter")
        }
        return AnyView(Text(string))
    }
}

private struct VStackRuntimeViewBuilder: RuntimeViewBuilder {
    let typeName = "VStack"

    func makeSwiftUIView(parameters: [RuntimeParameter], module: RuntimeModule, scope: RuntimeScope) throws -> AnyView {
        var spacing: CGFloat?
        var childViews: [AnyView] = []

        for parameter in parameters {
            if parameter.label == "spacing" {
                spacing = parameter.value.asDouble.map { CGFloat($0) }
                continue
            }

            switch parameter.value {
            case .array(let values):
                for value in values {
                    childViews.append(try module.realize(runtimeValue: value, scope: scope))
                }
            case .view(let runtimeView):
                childViews.append(try module.makeSwiftUIView(typeName: runtimeView.typeName, parameters: runtimeView.parameters, scope: scope))
            case .function(let function):
                let views = try module.runtimeViews(from: function, scope: scope)
                for runtimeView in views {
                    childViews.append(try module.makeSwiftUIView(typeName: runtimeView.typeName, parameters: runtimeView.parameters, scope: scope))
                }
            default:
                continue
            }
        }

        return AnyView(VStack(spacing: spacing) {
            ForEach(Array(childViews.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }
}
