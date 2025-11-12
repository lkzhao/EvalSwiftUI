import Foundation
import SwiftUI
import EvalSwiftIR

public final class RuntimeModule {
    public let ir: ModuleIR
    public let globalScope = RuntimeGlobalScope()
    public let viewBuilders: [String: any RuntimeViewBuilder]
    public var runtimeViews: [RuntimeView] = []

    public convenience init(source: String, viewBuilders: [any RuntimeViewBuilder] = []) {
        self.init(ir: SwiftIRParser().parseModule(source: source), viewBuilders: viewBuilders)
    }

    public init(ir: ModuleIR, viewBuilders: [any RuntimeViewBuilder] = []) {
        self.ir = ir
        let builders: [any RuntimeViewBuilder] = [
            TextRuntimeViewBuilder(),
            VStackRuntimeViewBuilder(),
            ButtonRuntimeViewBuilder(),
        ] + viewBuilders
        self.viewBuilders = Dictionary(uniqueKeysWithValues: builders.map({ ($0.typeName, $0) }))
        var runtimeViews: [RuntimeView] = []
        let interpreter = StatementInterpreter(module: self, scope: globalScope)
        _ = try? interpreter.execute(statements: ir.statements) { value in
            if case .view(let runtimeView) = value {
                runtimeViews.append(runtimeView)
            }
        }
        self.runtimeViews = runtimeViews
    }

    func viewDefinition(named name: String) -> CompiledViewDefinition? {
        guard let value = globalScope.get(name), case .viewDefinition(let definition) = value else { return nil }
        return definition
    }

    func builder(named name: String) -> (any RuntimeViewBuilder)? {
        viewBuilders[name]
    }

    @MainActor
    public func makeSwiftUIView(typeName: String, arguments: [RuntimeArgument], scope: RuntimeScope) throws -> AnyView {
        if let builder = builder(named: typeName) {
            return try builder.makeSwiftUIView(arguments: arguments, module: self, scope: scope)
        }
        if let definition = viewDefinition(named: typeName) {
            let renderer = try RuntimeViewRenderer(
                definition: definition,
                module: self,
                arguments: arguments,
                scope: scope,
            )
            return AnyView(RuntimeViewHost(renderer: renderer))
        }
        throw RuntimeError.unknownView(typeName)
    }

    @MainActor
    public func makeTopLevelSwiftUIViews() throws -> AnyView {
        guard !runtimeViews.isEmpty else {
            throw RuntimeError.invalidViewResult("Top-level statements did not produce any SwiftUI views")
        }

        let swiftUIViews = try runtimeViews.map { runtimeView in
            try makeSwiftUIView(typeName: runtimeView.typeName, arguments: runtimeView.arguments, scope: globalScope)
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

    // MARK: - Evaluation Helpers

    func evaluate(expression: ExprIR?, scope: RuntimeScope) throws -> RuntimeValue? {
        try ExpressionEvaluator(module: self, scope: scope).evaluate(expression: expression)
    }

    public func runtimeViews(from function: CompiledFunction, scope: RuntimeScope) throws -> [RuntimeView] {
        let scope = RuntimeFunctionScope(parent: scope)
        var collected: [RuntimeView] = []

        let interpreter = StatementInterpreter(module: self, scope: scope)
        _ = try interpreter.execute(statements: function.ir.body) { value in
            if case .view(let view) = value {
                collected.append(view)
            }
        }
        return collected
    }

    @MainActor
    public func realize(runtimeValue value: RuntimeValue, scope: RuntimeScope) throws -> AnyView {
        switch value {
        case .view(let runtimeView):
            return try makeSwiftUIView(typeName: runtimeView.typeName, arguments: runtimeView.arguments, scope: scope)
        case .viewDefinition(let definition):
            let renderer = try RuntimeViewRenderer(
                definition: definition,
                module: self,
                arguments: [],
                scope: scope,
            )
            return AnyView(RuntimeViewHost(renderer: renderer))
        default:
            throw RuntimeError.invalidViewResult("Expected view, got \(value)")
        }
    }

}
