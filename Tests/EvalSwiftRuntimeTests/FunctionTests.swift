import Testing
@testable import EvalSwiftRuntime
import EvalSwiftIR

struct FunctionTests {
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
            RuntimeArgument(label: "alias", value: .string("Beta")),
            RuntimeArgument(label: "person", value: .string("Alpha"))
        ]
        let value = try module.callMethod("primary", arguments: arguments)

        guard case .string(let result) = value else {
            throw TestFailure.expected("Expected string result, got \(String(describing: value))")
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
            RuntimeArgument(label: nil, value: .string("Positional")),
            RuntimeArgument(label: "alias", value: .string("Labeled"))
        ]
        let value = try module.callMethod("resolve", arguments: arguments)

        guard case .string(let result) = value else {
            throw TestFailure.expected("Expected string, got \(String(describing: value))")
        }

        #expect(result == "Positional")
    }
}
