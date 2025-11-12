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
        let statementInterpreter = StatementInterpreter(module: self, scope: globalScope)
        let values = try? statementInterpreter.executeAndCollectRuntimeViews(statements: ir.statements)
        self.runtimeViews = values ??  []
    }

    func viewDefinition(named name: String) -> CompiledViewDefinition? {
        guard let value = try? globalScope.get(name), case .viewDefinition(let definition) = value else { return nil }
        return definition
    }

    func builder(named name: String) -> (any RuntimeViewBuilder)? {
        viewBuilders[name]
    }

    @MainActor
    public func makeTopLevelSwiftUIViews() throws -> AnyView {
        guard !runtimeViews.isEmpty else {
            throw RuntimeError.invalidViewResult("Top-level statements did not produce any SwiftUI views")
        }

        let swiftUIViews = try runtimeViews.map { runtimeView in
            try runtimeView.makeSwiftUIView(module: self, scope: globalScope)
        }

        return AnyView(VStack {
            ForEach(Array(swiftUIViews.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }
}
