//
//  ArgumentEvaluator.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/14/25.
//

import EvalSwiftIR

struct ArgumentEvaluator {
    static func evaluate(
        parameters: [RuntimeParameter],
        arguments: [FunctionCallArgumentIR],
        scope: RuntimeScope
    ) throws -> [RuntimeArgument] {
        var evaluatedArguments: [RuntimeArgument] = []
        var argumentIndex = 0

        for parameter in parameters {
            if argumentIndex >= arguments.count {
                guard parameter.defaultValue != nil else {
                    throw RuntimeError.invalidArgumentCount(expected: parameters.count, got: arguments.count)
                }
                continue
            }

            let argumentIR = arguments[argumentIndex]
            switch match(argumentIR, to: parameter) {
            case .consume:
                evaluatedArguments.append(
                    try evaluate(argument: argumentIR, for: parameter, scope: scope)
                )
                argumentIndex += 1
            case .skip:
                evaluatedArguments.append(
                    try evaluate(argument: nil, for: parameter, scope: scope)
                )
            case .mismatch(let message):
                throw RuntimeError.invalidViewArgument(message)
            }
        }

        if argumentIndex != arguments.count {
            if argumentIndex < arguments.count, let extraLabel = arguments[argumentIndex].label {
                throw RuntimeError.invalidViewArgument("Unexpected argument label '\(extraLabel)'.")
            }
            throw RuntimeError.invalidArgumentCount(expected: parameters.count, got: arguments.count)
        }

        return evaluatedArguments
    }

    private static func evaluate(
        argument: FunctionCallArgumentIR?,
        for parameter: RuntimeParameter,
        scope: RuntimeScope
    ) throws -> RuntimeArgument {
        var argumentScope = scope
        if let type = parameter.type, let typeScope = try? scope.type(named: type) {
            argumentScope = TypeHintScope(parent: scope, type: typeScope)
        }
        guard let argumentValue = try ExpressionEvaluator.evaluate(argument?.value ?? parameter.defaultValue, scope: argumentScope) else {
            throw RuntimeError.unsupportedExpression("Unable to evaluate argument for parameter '\(parameter.name)'")
        }
        return RuntimeArgument(name: parameter.name, value: argumentValue)
    }

    private static func candidateLabels(for parameter: RuntimeParameter) -> [String] {
        [parameter.label, parameter.name].compactMap { label in
            guard let label, !label.isEmpty else { return nil }
            return label
        }
    }

    private enum MatchDecision {
        case consume
        case skip
        case mismatch(String)
    }

    private static func match(
        _ argument: FunctionCallArgumentIR,
        to parameter: RuntimeParameter
    ) -> MatchDecision {
        let hasDefault = parameter.defaultValue != nil
        let parameterName = parameter.label ?? parameter.name

        if let label = argument.label {
            let candidates = candidateLabels(for: parameter)
            if candidates.contains(label) {
                return .consume
            }
            if hasDefault {
                return .skip
            }
            return .mismatch("Unexpected argument label '\(label)' for parameter '\(parameterName)'.")
        }

        if parameter.label == nil {
            return .consume
        }

        if hasDefault {
            return .skip
        }

        if isClosure(argument) {
            return .consume
        }

        return .mismatch("Missing argument label '\(parameterName)'.")
    }

    private static func isClosure(_ argument: FunctionCallArgumentIR) -> Bool {
        if case .function = argument.value {
            return true
        }
        return false
    }
}

fileprivate class TypeHintScope: RuntimeScope {
    public var storage: RuntimeScopeStorage
    public var parent: RuntimeScope?
    init(parent: RuntimeScope, type: RuntimeScope) {
        self.parent = parent
        self.storage = type.storage
    }
}
