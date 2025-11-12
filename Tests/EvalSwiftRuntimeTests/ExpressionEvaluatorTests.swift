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

    @Test func supportsNumericTypeInitializers() throws {
        let source = """
        var intValue: Int = Int(3.7)
        var doubleValue: Double = Double(1)
        var floatValue: Float = Float(2.5)
        var cgValue: CGFloat = CGFloat(4.25)
        """

        let module = RuntimeModule(source: source)

        guard case .int(let intValue) = try module.get("intValue"),
              case .double(let doubleValue) = try module.get("doubleValue"),
              case .double(let floatValue) = try module.get("floatValue"),
              case .double(let cgValue) = try module.get("cgValue") else {
            throw TestFailure.expected("Expected numeric values to be stored")
        }

        #expect(intValue == 3)
        #expect(doubleValue == 1)
        #expect(floatValue == 2.5)
        #expect(cgValue == 4.25)
    }

    @Test func coercesFloatBindingsToDoubleStorage() throws {
        let source = """
        var spacing: CGFloat = 0

        func adjust() {
            spacing = spacing + 0.5
            spacing = spacing + 1
        }

        adjust()
        """

        let module = RuntimeModule(source: source)
        guard case .double(let spacing) = try module.get("spacing") else {
            throw TestFailure.expected("Expected spacing to be stored as Double")
        }

        #expect(spacing == 1.5)
    }

    @Test func supportsMixingIntsAndDoubleConversions() throws {
        let source = """
        var value = 3
        var newValue = Double(value)
        var finalValue = value + Double(value) / 2
        """

        let module = RuntimeModule(source: source)

        guard case .double(let newValue) = try module.get("newValue"),
              case .double(let finalValue) = try module.get("finalValue") else {
            throw TestFailure.expected("Expected Double storage for converted values")
        }

        #expect(newValue == 3)
        #expect(finalValue == 4.5)
    }
}
