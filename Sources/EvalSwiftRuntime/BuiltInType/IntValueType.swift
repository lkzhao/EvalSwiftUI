

public struct IntValueType: RuntimeBuiltInType {
    public let name = "Int"
    public func makeValue(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue {
        guard arguments.count == 1 else {
            throw RuntimeError.unsupportedExpression("Invalid number of arguments for Int initializer")
        }
        let argValue = arguments[0].value
        if let intValue = argValue.asInt {
            return .int(intValue)
        } else {
            throw RuntimeError.unsupportedExpression("Cannot convert \(argValue) to Int")
        }
    }
}
