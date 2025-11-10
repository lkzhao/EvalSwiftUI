import Testing
@testable import EvalSwiftRuntime
import EvalSwiftIR

struct RuntimeViewDefinitionTests {
    @Test func instantiatesViewBodyReturnsPropertyValue() throws {
        let source = """
        struct SampleView: View {
            var title: String = "Hello"

            var body: some View {
                title
            }
        }
        """

        let module = makeModule(source: source)
        let compiled = try compiledView(named: "SampleView", from: module)
        let rendered = try compiled.instantiate(scope: module.globalScope)

        guard case .string(let message) = rendered else {
            throw TestFailure.expected("Expected string result, got \(rendered)")
        }

        #expect(message == "Hello")
    }

    @Test func implicitReturnUsesLastExpression() throws {
        let source = """
        struct ImplicitView: View {
            var title: String = "Implicit"

            var body: some View {
                "Ignored"
                title
            }
        }
        """

        let module = makeModule(source: source)
        let compiled = try compiledView(named: "ImplicitView", from: module)
        let rendered = try compiled.instantiate(scope: module.globalScope)

        guard case .string(let message) = rendered else {
            throw TestFailure.expected("Expected string result, got \(rendered)")
        }

        #expect(message == "Implicit")
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
}
