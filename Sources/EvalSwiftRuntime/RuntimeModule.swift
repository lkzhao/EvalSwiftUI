import Foundation
import EvalSwiftIR

public final class RuntimeModule {
    private let ir: ModuleIR
    private(set) var functions: [String: CompiledFunction] = [:]
    let globals = RuntimeScope()

    public init(ir: ModuleIR) {
        self.ir = ir
        compileBindings()
        compileFunctions()
    }

    public func call(function name: String, arguments: [RuntimeValue] = []) throws -> RuntimeValue {
        guard let function = functions[name] else {
            throw RuntimeError.unknownFunction(name)
        }
        return try function.invoke(arguments: arguments)
    }

    // MARK: - Compilation

    private func compileBindings() {
        for binding in ir.bindings {
            let value = try? evaluate(expression: binding.initializer, scope: globals) ?? .void
            globals.set(binding.name, value: value ?? .void)
        }
    }

    private func compileFunctions() {
        for functionIR in ir.functions {
            let compiled = CompiledFunction(ir: functionIR, module: self)
            functions[functionIR.name] = compiled
        }
    }

    // MARK: - Evaluation Helpers

    func evaluate(expression: ExprIR?, scope: RuntimeScope) throws -> RuntimeValue? {
        guard let expression else { return nil }
        switch expression {
        case .identifier(let name):
            if let local = scope.get(name) {
                return local
            }
            throw RuntimeError.unknownIdentifier(name)
        case .literal(let raw):
            if let number = Double(raw) {
                return .number(number)
            }
            if raw == "true" { return .bool(true) }
            if raw == "false" { return .bool(false) }
            return .string(raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
        case .member(let base, let name):
            let baseValue = try evaluate(expression: base, scope: scope)
            let description = "\(describe(value: baseValue))\(String.memberSeparator)\(name)"
            return .string(description)
        case .call(let callee, let arguments):
            guard case .identifier(let functionName) = callee else {
                throw RuntimeError.unsupportedExpression("Non-identifier calls are not supported")
            }
            let resolvedArguments = try arguments.map { try evaluate(expression: $0.value, scope: scope) ?? .void }
            guard let compiled = functions[functionName] else {
                throw RuntimeError.unknownFunction(functionName)
            }
            return try compiled.invoke(arguments: resolvedArguments, scope: scope)
        case .unknown(let raw):
            throw RuntimeError.unsupportedExpression(raw)
        }
    }

    private func describe(value: RuntimeValue?) -> String {
        guard let value else { return "nil" }
        switch value {
        case .number(let number):
            return String(number)
        case .string(let string):
            return string
        case .bool(let bool):
            return String(bool)
        case .view(let description):
            return "<View: \(description.name)>"
        case .void:
            return "void"
        }
    }
}

private extension String {
    static let memberSeparator = "."
}
