import Testing
@testable import EvalSwiftRuntime

struct ExpressionEvaluatorTests {
    @Test func supportsBasicArithmeticExpressions() throws {
        let source = """
        var count: Int = 0

        func increment() {
            count = count + 1
            count = count * 2
            count = count - 3
        }

        increment()
        """

        let module = RuntimeModule(source: source)
        guard case .int(let value) = try module.get("count") else {
            throw TestFailure.expected("Expected stored count value to be an Int, got \\(try module.get(\"count\"))")
        }

        #expect(value == -1)
    }

    @Test func supportsCompoundAssignmentOperators() throws {
        let source = """
        var count: Int = 1
        var delta: Int = 2

        func mutate() {
            count += delta + 1
            count -= delta
            count *= delta + 1
            count /= 2
            count %= 4
        }

        mutate()
        """

        let module = RuntimeModule(source: source)
        guard case .int(let value) = try module.get("count") else {
            throw TestFailure.expected("Expected count to be an Int")
        }

        #expect(value == 3)
    }

    @Test func supportsUnaryPrefixOperators() throws {
        let source = """
        var base: Int = 5
        var negated: Int = 0
        var positive: Int = 0

        func flip() {
            negated = -base
            positive = +negated
        }

        flip()
        """

        let module = RuntimeModule(source: source)
        guard case .int(let negated) = try module.get("negated"),
              case .int(let positive) = try module.get("positive") else {
            throw TestFailure.expected("Expected negated and positive to both be Ints")
        }

        #expect(negated == -5)
        #expect(positive == -5)
    }
}
