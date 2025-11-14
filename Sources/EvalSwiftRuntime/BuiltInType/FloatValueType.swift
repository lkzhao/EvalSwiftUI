

public struct FloatValueType: RuntimeBuiltInType {
    public let name: String
    public init(name: String) {
        self.name = name
    }
    public func makeValue(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue {
        guard arguments.count == 1 else {
            throw RuntimeError.unsupportedExpression("Invalid number of arguments for Double initializer")
        }
        let argValue = arguments[0].value
        if let doubleValue = argValue.asDouble {
            return .double(doubleValue)
        } else {
            throw RuntimeError.unsupportedExpression("Cannot convert \(argValue) to Double")
        }
    }
}
