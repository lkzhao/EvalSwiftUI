import EvalSwiftIR

public typealias RuntimeParameter = FunctionParameterIR

public struct RuntimeArgument {
    public let label: String?
    public let value: RuntimeValue

    public init(label: String?, value: RuntimeValue) {
        self.label = label
        self.value = value
    }
}

struct ArgumentEvaluator {
    static func evaluate(
        parameters: [RuntimeParameter],
        arguments: [FunctionCallArgumentIR],
        scope: RuntimeScope
    ) throws -> [RuntimeArgument] {
        // TODO: Handle parameters with default values.
        guard parameters.count == arguments.count else {
            throw RuntimeError.invalidArgumentCount(expected: parameters.count, got: arguments.count)
        }
        guard zip(parameters, arguments).allSatisfy({ (param, arg) in
            param.label == arg.label
        }) else {
            throw RuntimeError.invalidViewArgument("Argument labels do not match parameter labels.")
        }
        var evaluatedArguments: [RuntimeArgument] = []
        for (index, parameter) in parameters.enumerated() {
            let argumentIR = arguments[index]
            var argumentScope = scope
            if let type = parameter.type {
                let typeScope = try scope.type(named: type)
                argumentScope = TypeHintScope(parent: scope, type: typeScope)
            }
            guard let argumentValue = try ExpressionEvaluator.evaluate(argumentIR.value, scope: argumentScope) else {
                throw RuntimeError.unsupportedExpression("Unable to evaluate argument for parameter '\(parameter.name)'")
            }
            evaluatedArguments.append(RuntimeArgument(label: argumentIR.label, value: argumentValue))
        }
        return evaluatedArguments
    }
}

class TypeHintScope: RuntimeScope {
    public var storage: RuntimeScopeStorage
    public var parent: RuntimeScope?
    init(parent: RuntimeScope, type: RuntimeScope) {
        self.parent = parent
        self.storage = type.storage
    }
}
