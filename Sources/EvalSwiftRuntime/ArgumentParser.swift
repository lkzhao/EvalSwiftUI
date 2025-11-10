import EvalSwiftIR

struct ArgumentParser {
    private let parameters: [FunctionParameterIR]

    init(parameters: [FunctionParameterIR]) {
        self.parameters = parameters
    }

    func resolveValues(from arguments: [RuntimeParameter]) -> [RuntimeValue] {
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

        func nextValue(for parameter: FunctionParameterIR) -> RuntimeValue {
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

            return .void
        }

        return parameters.map { nextValue(for: $0) }
    }
}
