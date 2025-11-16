import Testing
@testable import EvalSwiftIR
@testable import EvalSwiftRuntime

struct ExpressionEvaluatorTests {
    @Test func structTest() throws {
        let source = """
        struct Counter {
            var count: Int = 0
        }

        let k = Counter()
        k.count += 1
        """

        let module = try RuntimeModule(source: source)
        guard case .instance(let instance) = try module.get("k"), case .int(let count) = try instance.get("count") else {
            throw TestFailure.expected("Expected stored count value to be an Int, got \\(try module.get(\"count\"))")
        }

        #expect(count == 1)
    }

    @Test func supportsEnumDeclarations() throws {
        let source = """
        enum Field {
            case email
            case password
        }

        var selected = Field.email
        selected = Field.password
        """

        let module = try RuntimeModule(source: source)
        guard case .enumCase(let value) = try module.get("selected") else {
            throw TestFailure.expected("Expected selected to store an enum case")
        }

        #expect(value == RuntimeEnumCase(typeName: "Field", caseName: "password"))
    }

    @Test func supportsNestedEnumDeclarations() throws {
        let source = """
        struct Container {
            enum Field {
                case email
                case password
            }

            var field = Field.email
        }

        let container = Container()
        """

        let module = try RuntimeModule(source: source)
        guard case .instance(let instance) = try module.get("container"),
              case .enumCase(let field) = try instance.get("field") else {
            throw TestFailure.expected("Expected container.field to be stored as an enum case")
        }

        #expect(field == RuntimeEnumCase(typeName: "Container.Field", caseName: "email"))
    }
    @Test func nestedStructTest() throws {
        let source = """
        struct Counter {
            var count: Int = 0
        }
        struct Outer {
            var counter = Counter()
        }

        let k = Outer()
        k.counter.count += 1
        """

        let module = try RuntimeModule(source: source)
        guard case .instance(let instance) = try module.get("k"), case .instance(let counter) = try instance.get("counter"), case .int(let count) = try counter.get("count") else {
            throw TestFailure.expected("Expected stored count value to be an Int, got \\(try module.get(\"count\"))")
        }

        #expect(count == 1)
    }
    @Test func staticStructTest() throws {
        let source = """
        struct Counter {
            static var count: Int = 0
        }

        Counter.count += 1
        """

        let module = try RuntimeModule(source: source)
        guard case .type(let type) = try module.get("Counter"), case .int(let count) = try type.get("count") else {
            throw TestFailure.expected("Expected stored count value to be an Int, got \\(try module.get(\"count\"))")
        }

        #expect(count == 1)
    }
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

        let module = try RuntimeModule(source: source)
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

        let module = try RuntimeModule(source: source)
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

        let module = try RuntimeModule(source: source)
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

        let module = try RuntimeModule(source: source)

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

        let module = try RuntimeModule(source: source)
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

        let module = try RuntimeModule(source: source)

        guard case .double(let newValue) = try module.get("newValue"),
              case .double(let finalValue) = try module.get("finalValue") else {
            throw TestFailure.expected("Expected Double storage for converted values")
        }

        #expect(newValue == 3)
        #expect(finalValue == 4.5)
    }

    @Test func rangeOperatorsProduceArrays() throws {
        let source = """
        var exclusive = 0..<3
        var inclusive = 1...3
        """

        let module = try RuntimeModule(source: source)

        guard case .array(let exclusiveValues) = try module.get("exclusive"),
              case .array(let inclusiveValues) = try module.get("inclusive") else {
            throw TestFailure.expected("Expected ranges to evaluate to arrays")
        }

        #expect(exclusiveValues.count == 3)
        #expect(inclusiveValues.count == 3)
        let exclusiveInts = exclusiveValues.compactMap { value -> Int? in
            if case .int(let number) = value { return number }
            return nil
        }
        let inclusiveInts = inclusiveValues.compactMap { value -> Int? in
            if case .int(let number) = value { return number }
            return nil
        }

        #expect(exclusiveInts == [0, 1, 2])
        #expect(inclusiveInts == [1, 2, 3])
    }

    @Test func supportsIfStatementsInsideFunctions() throws {
        let source = """
        var value: Int? = 1

        func update() {
            if let unwrapped = value {
                value = unwrapped + 1
            } else {
                value = 0
            }
        }

        update()
        """

        let module = try RuntimeModule(source: source)
        guard case .int(let result) = try module.get("value") else {
            throw TestFailure.expected("Expected value to be Int")
        }

        #expect(result == 2)
    }

    @Test func supportsDefaultedFunctionArguments() throws {
        let source = """
        func greet(greeting: String = "Hello", name: String) -> String {
            "\\(greeting), \\(name)"
        }

        let implicit = greet(name: "Eval")
        let explicit = greet(greeting: "Hi", name: "Swift")
        """

        let module = try RuntimeModule(source: source)
        guard case .string(let implicit) = try module.get("implicit"),
              case .string(let explicit) = try module.get("explicit") else {
            throw TestFailure.expected("Expected greeting strings to be stored")
        }

        #expect(implicit == "Hello, Eval")
        #expect(explicit == "Hi, Swift")
    }

    @Test func allowsTrailingClosureAfterDefaultedParameters() throws {
        let source = """
        func run(count: Int = 1, action: () -> Int) -> Int {
            action() + count
        }

        let once = run { 5 }
        let twice = run(count: 2) { 3 }
        """

        let module = try RuntimeModule(source: source)
        guard case .int(let once) = try module.get("once"),
              case .int(let twice) = try module.get("twice") else {
            throw TestFailure.expected("Expected run results to be Int values")
        }

        #expect(once == 6)
        #expect(twice == 5)
    }

    @Test func supportsDictionarySubscripts() throws {
        let module = try RuntimeModule(ir: ModuleIR(statements: []))
        let storage: [AnyHashable: RuntimeValue] = [
            AnyHashable("primary"): .string("Alpha"),
            AnyHashable(2): .int(20)
        ]
        module.define("lookup", value: .dictionary(storage))

        let stringLookup = ExprIR.`subscript`(
            base: .identifier("lookup"),
            arguments: [FunctionCallArgumentIR(label: nil, value: .string("primary"))]
        )
        guard case .string(let primaryValue)? = try ExpressionEvaluator.evaluate(stringLookup, scope: module) else {
            throw TestFailure.expected("Expected dictionary lookup to return stored string value.")
        }
        #expect(primaryValue == "Alpha")

        let missingLookup = ExprIR.`subscript`(
            base: .identifier("lookup"),
            arguments: [FunctionCallArgumentIR(label: nil, value: .string("missing"))]
        )
        guard case .void? = try ExpressionEvaluator.evaluate(missingLookup, scope: module) else {
            throw TestFailure.expected("Missing dictionary keys should evaluate to void.")
        }
    }
}
