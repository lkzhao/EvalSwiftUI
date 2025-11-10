import Testing
@testable import EvalSwiftRuntime
import EvalSwiftIR

struct CompiledFunctionTests {
    @Test func matchesArgumentsByLabelRegardlessOfOrder() throws {
        let source = """
        func primary(person name: String, alias: String) -> String {
            name
        }
        """

        let parser = SwiftIRParser()
        let moduleIR = parser.parseModule(source: source)
        let module = RuntimeModule(ir: moduleIR)

        let arguments = [
            RuntimeParameter(label: "alias", value: .string("Beta")),
            RuntimeParameter(label: "person", value: .string("Alpha"))
        ]
        let value = try module.call(function: "primary", arguments: arguments)

        guard case .string(let result) = value else {
            throw TestFailure.expected("Expected string result, got \(value)")
        }

        #expect(result == "Alpha")
    }

    @Test func fallsBackToPositionalArgumentsWhenLabelMissing() throws {
        let source = """
        func resolve(person name: String, alias: String) -> String {
            name
        }
        """

        let parser = SwiftIRParser()
        let module = RuntimeModule(ir: parser.parseModule(source: source))

        let arguments = [
            RuntimeParameter(label: nil, value: .string("Positional")),
            RuntimeParameter(label: "alias", value: .string("Labeled"))
        ]
        let value = try module.call(function: "resolve", arguments: arguments)

        guard case .string(let result) = value else {
            throw TestFailure.expected("Expected string, got \(value)")
        }

        #expect(result == "Positional")
    }
}
