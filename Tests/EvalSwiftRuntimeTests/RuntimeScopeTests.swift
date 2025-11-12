import Testing
@testable import EvalSwiftRuntime

struct RuntimeScopeTests {
    @Test func setUpdatesExistingValueWhenTypesMatch() throws {
        let scope = RuntimeFunctionScope(parent: nil)
        scope.define("value", value: .int(1))

        try scope.set("value", value: .int(2))

        guard case .int(let updated) = try scope.get("value") else {
            throw TestFailure.expected("Expected stored int value")
        }

        #expect(updated == 2)
    }

    @Test func setThrowsWhenTypesMismatch() throws {
        let scope = RuntimeFunctionScope(parent: nil)
        scope.define("value", value: .int(1))

        do {
            try scope.set("value", value: .string("nope"))
            throw TestFailure.expected("Expected type mismatch error")
        } catch RuntimeError.unsupportedAssignment(let message) {
            #expect(message.contains("Type mismatch for 'value'"))
        }
    }

    @Test func getThrowsForMissingIdentifier() throws {
        let scope = RuntimeFunctionScope(parent: nil)

        do {
            _ = try scope.get("missing")
            throw TestFailure.expected("Expected missing identifier to throw")
        } catch RuntimeError.unknownIdentifier(let name) {
            #expect(name == "missing")
        }
    }
}
