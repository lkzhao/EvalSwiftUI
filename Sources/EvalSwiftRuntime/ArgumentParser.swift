import EvalSwiftIR

struct ArgumentParser {
    private let parameters: [FunctionParameterIR]

    init(parameters: [FunctionParameterIR]) {
        self.parameters = parameters
    }

    func bind(arguments: [RuntimeParameter], into scope: RuntimeScope, module: RuntimeModule) throws {
        var labeledArguments: [String: RuntimeValue] = [:]
        var positionalArguments: [RuntimeValue] = []

        for argument in arguments {
            if let label = argument.label {
                labeledArguments[label] = argument.value
            } else {
                positionalArguments.append(argument.value)
            }
        }

        var positionalIndex = 0

        func consumeValue(for parameter: FunctionParameterIR) -> RuntimeValue? {
            let candidateLabels = [parameter.label, parameter.name]
                .compactMap { $0 }
                .filter { !$0.isEmpty }

            for label in candidateLabels {
                if let value = labeledArguments.removeValue(forKey: label) {
                    return value
                }
            }

            if positionalIndex < positionalArguments.count {
                let value = positionalArguments[positionalIndex]
                positionalIndex += 1
                return value
            }

            return nil
        }

        for parameter in parameters {
            if let provided = consumeValue(for: parameter) {
                scope.set(parameter.name, value: provided)
                continue
            }

            if let defaultExpr = parameter.defaultValue {
                let value = try module.evaluate(expression: defaultExpr, scope: scope) ?? .void
                scope.set(parameter.name, value: value)
            } else {
                scope.set(parameter.name, value: .void)
            }
        }
    }
}
