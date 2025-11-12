import Foundation
import SwiftUI
import EvalSwiftIR

public final class RuntimeModule {
    private let ir: ModuleIR
    private let rootInstance = RuntimeInstance()
    private var viewBuilders: [String: any RuntimeViewBuilder] = [:]

    public convenience init(source: String) {
        self.init(ir: SwiftIRParser().parseModule(source: source))
    }

    public init(ir: ModuleIR) {
        self.ir = ir
        registerViewBuilder(TextRuntimeViewBuilder())
        registerViewBuilder(VStackRuntimeViewBuilder())
        registerViewBuilder(ButtonRuntimeViewBuilder())
        compileBindings()
    }

    public func call(function name: String, arguments: [RuntimeParameter] = []) throws -> RuntimeValue {
        guard let value = rootInstance.get(name),
              case .function(let function) = value else {
            throw RuntimeError.unknownFunction(name)
        }
        return try function.invoke(arguments: arguments, instance: rootInstance)
    }

    public func value(for name: String) -> RuntimeValue? {
        rootInstance.get(name)
    }

    public var globalInstance: RuntimeInstance {
        rootInstance
    }

    func viewDefinition(named name: String) -> CompiledViewDefinition? {
        if let value = rootInstance.get(name), case .viewDefinition(let definition) = value {
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

    @MainActor
    public func makeSwiftUIView(typeName: String, parameters: [RuntimeParameter], instance: RuntimeInstance) throws -> AnyView {
        if let builder = builder(named: typeName) {
            return try builder.makeSwiftUIView(parameters: parameters, module: self, instance: instance)
        }
        if let definition = viewDefinition(named: typeName) {
            let renderer = try RuntimeViewRenderer(
                definition: definition,
                module: self,
                parentInstance: instance,
                parameters: parameters
            )
            return AnyView(RuntimeViewHost(renderer: renderer))
        }
        throw RuntimeError.unknownView(typeName)
    }

    @MainActor
    public func makeTopLevelSwiftUIViews() throws -> AnyView {
        let statementInstance = RuntimeInstance(parent: rootInstance)
        var runtimeViews: [RuntimeView] = []

        let interpreter = StatementInterpreter(module: self, instance: statementInstance)
        _ = try interpreter.execute(statements: ir.statements) { value in
            if case .view(let runtimeView) = value {
                runtimeViews.append(runtimeView)
            }
        }

        guard !runtimeViews.isEmpty else {
            throw RuntimeError.invalidViewResult("Top-level statements did not produce any SwiftUI views")
        }

        let swiftUIViews = try runtimeViews.map { runtimeView in
            try makeSwiftUIView(typeName: runtimeView.typeName, parameters: runtimeView.parameters, instance: statementInstance)
        }

        if swiftUIViews.count == 1, let first = swiftUIViews.first {
            return first
        }

        return AnyView(VStack {
            ForEach(Array(swiftUIViews.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }

    // MARK: - Compilation

    private func compileBindings() {
        for binding in ir.bindings {
            let value = try? evaluate(expression: binding.initializer, instance: rootInstance) ?? .void
            rootInstance.set(binding.name, value: value ?? .void)
        }
    }

    // MARK: - Evaluation Helpers

    func evaluate(expression: ExprIR?, instance: RuntimeInstance) throws -> RuntimeValue? {
        try ExpressionEvaluator(module: self, instance: instance).evaluate(expression: expression)
    }

    public func runtimeViews(from function: CompiledFunction, instance: RuntimeInstance) throws -> [RuntimeView] {
        let closureInstance = RuntimeInstance(parent: instance)
        var collected: [RuntimeView] = []

        let interpreter = StatementInterpreter(module: self, instance: closureInstance)
        _ = try interpreter.execute(statements: function.ir.body) { value in
            if case .view(let view) = value {
                collected.append(view)
            }
        }
        return collected
    }

    @MainActor
    public func realize(runtimeValue value: RuntimeValue, instance: RuntimeInstance) throws -> AnyView {
        switch value {
        case .view(let runtimeView):
            return try makeSwiftUIView(typeName: runtimeView.typeName, parameters: runtimeView.parameters, instance: instance)
        case .viewDefinition(let definition):
            let renderer = try RuntimeViewRenderer(
                definition: definition,
                module: self,
                parentInstance: instance,
                parameters: []
            )
            return AnyView(RuntimeViewHost(renderer: renderer))
        default:
            throw RuntimeError.invalidViewResult("Expected view, got \(value)")
        }
    }

}
