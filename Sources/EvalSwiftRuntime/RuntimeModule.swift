import Foundation
import EvalSwiftIR

public final class RuntimeModule {
    private let ir: ModuleIR
    let globals = RuntimeScope()

    public init(ir: ModuleIR) {
        self.ir = ir
        compileBindings()
    }

    public func call(function name: String, arguments: [RuntimeValue] = []) throws -> RuntimeValue {
        guard let value = globals.get(name),
              case .function(let function) = value else {
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

    // MARK: - Evaluation Helpers

    func evaluate(expression: ExprIR?, scope: RuntimeScope) throws -> RuntimeValue? {
        try RuntimeEvaluator(module: self, scope: scope).evaluate(expression: expression)
    }
}
