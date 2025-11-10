import Foundation
import EvalSwiftIR

public final class CompiledViewDefinition {
    public let ir: ViewDefinitionIR
    private unowned let module: RuntimeModule

    init(ir: ViewDefinitionIR, module: RuntimeModule) {
        self.ir = ir
        self.module = module
    }

    public func instantiate(arguments: [RuntimeValue] = [], scope: RuntimeScope) throws -> RuntimeValue {
        let localScope = RuntimeScope(parent: scope)
        bind(parameters: ir.parameters, arguments: arguments, into: localScope)
        try initializeProperties(in: localScope)
        registerMethods(in: localScope)
        let interpreter = StatementInterpreter(module: module, scope: localScope)
        return try interpreter.execute(statements: ir.bodyStatements)
    }

    private func bind(parameters: [FunctionParameterIR], arguments: [RuntimeValue], into localScope: RuntimeScope) {
        for (index, parameter) in parameters.enumerated() {
            let argument = index < arguments.count ? arguments[index] : .void
            localScope.set(parameter.internalName, value: argument)
        }
    }

    private func initializeProperties(in localScope: RuntimeScope) throws {
        for property in ir.properties {
            let value = try module.evaluate(expression: property.initializer, scope: localScope) ?? .void
            localScope.set(property.name, value: value)
        }
    }

    private func registerMethods(in localScope: RuntimeScope) {
        for method in ir.methods {
            let compiled = CompiledFunction(ir: method, module: module)
            localScope.set(method.name, value: .function(compiled))
        }
    }
}
