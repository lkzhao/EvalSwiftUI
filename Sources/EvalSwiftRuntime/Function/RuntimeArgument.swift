import EvalSwiftIR

//public typealias RuntimeParameter = FunctionParameterIR

public struct RuntimeParameter: Hashable {
    public let label: String?
    public let name: String
    public let type: String?
    public let defaultValue: RuntimeValue?

    init(ir: FunctionParameterIR, scope: RuntimeScope) throws {
        self.label = ir.label
        self.name = ir.name
        self.type = ir.type
        self.defaultValue = try ir.defaultValue.flatMap { expr in
            try ExpressionEvaluator.evaluate(expr, scope: scope)
        }
    }

    init(name: String, type: String? = nil, defaultValue: RuntimeValue? = nil) {
        self.label = name
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }

    init(label: String, name: String, type: String? = nil, defaultValue: RuntimeValue? = nil) {
        self.label = label == "_" ? nil : label
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }

    public static func == (lhs: RuntimeParameter, rhs: RuntimeParameter) -> Bool {
        return lhs.label == rhs.label &&
            lhs.name == rhs.name &&
            lhs.type == rhs.type &&
            lhs.defaultValue?.valueType == rhs.defaultValue?.valueType
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(defaultValue?.valueType)
    }
}

public struct RuntimeArgument {
    public let name: String
    public let value: RuntimeValue

    public init(name: String, value: RuntimeValue) {
        self.name = name
        self.value = value
    }
}
