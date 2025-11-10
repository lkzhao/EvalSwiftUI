import Foundation
import SwiftUI
import EvalSwiftIR

public final class RuntimeModule {
    private let ir: ModuleIR
    private let globals = RuntimeScope()
    private var viewBuilders: [String: any RuntimeViewBuilder] = [:]

    public init(ir: ModuleIR) {
        self.ir = ir
        compileBindings()
    }

    public func call(function name: String, arguments: [RuntimeParameter] = []) throws -> RuntimeValue {
        guard let value = globals.get(name),
              case .function(let function) = value else {
            throw RuntimeError.unknownFunction(name)
        }
        return try function.invoke(arguments: arguments, scope: globals)
    }

    public func value(for name: String) -> RuntimeValue? {
        globals.get(name)
    }

    public var globalScope: RuntimeScope {
        globals
    }

    func viewDefinition(named name: String) -> CompiledViewDefinition? {
        if let value = globals.get(name), case .viewDefinition(let definition) = value {
            return definition
        }
        return nil
    }

    func builder(named name: String) -> (any RuntimeViewBuilder)? {
        viewBuilders[name]
    }

    public func registerViewBuilder(_ builder: any RuntimeViewBuilder) {
        viewBuilders[builder.typeName] = builder
    }

    public func makeSwiftUIView(typeName: String, parameters: [RuntimeParameter], scope: RuntimeScope) throws -> AnyView {
        if let builder = builder(named: typeName) {
            return try builder.makeSwiftUIView(parameters: parameters, module: self, scope: scope)
        }
        if let definition = viewDefinition(named: typeName) {
            let value = try definition.instantiate(scope: scope, parameters: parameters)
            return try realize(runtimeValue: value, scope: scope)
        }
        throw RuntimeError.unknownView(typeName)
    }

    // MARK: - Compilation

    private func compileBindings() {
        for binding in ir.bindings {
            let value = try? evaluate(expression: binding.initializer, scope: globals) ?? .void
            globals.set(binding.name, value: value ?? .void)
        }
    }

    // MARK: - Evaluation Helpers

    func evaluate(expression: ExprIR?, scope: RuntimeScope) throws -> RuntimeValue? {
        try ExpressionEvaluator(module: self, scope: scope).evaluate(expression: expression)
    }

    public func runtimeViews(from function: CompiledFunction, scope: RuntimeScope) throws -> [RuntimeView] {
        let closureScope = RuntimeScope(parent: scope)
        var collected: [RuntimeView] = []

        let interpreter = StatementInterpreter(module: self, scope: closureScope)
        _ = try interpreter.execute(statements: function.ir.body) { value in
            if case .view(let view) = value {
                collected.append(view)
            }
        }
        return collected
    }

    public func realize(runtimeValue value: RuntimeValue, scope: RuntimeScope) throws -> AnyView {
        switch value {
        case .view(let runtimeView):
            return try makeSwiftUIView(typeName: runtimeView.typeName, parameters: runtimeView.parameters, scope: scope)
        case .viewDefinition(let definition):
            let produced = try definition.instantiate(scope: scope)
            return try realize(runtimeValue: produced, scope: scope)
        default:
            throw RuntimeError.invalidViewResult("Expected view, got \(value)")
        }
    }

}
