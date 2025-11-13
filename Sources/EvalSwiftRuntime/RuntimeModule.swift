import Foundation
import SwiftUI
import EvalSwiftIR

public final class RuntimeModule: RuntimeScope {
    public var storage: [String: RuntimeValue] = [:]
    public var runtimeViews: [RuntimeView] = []

    public convenience init(source: String, viewBuilders: [any RuntimeViewBuilder] = []) {
        self.init(ir: SwiftIRParser().parseModule(source: source), viewBuilders: viewBuilders)
    }

    public init(ir: ModuleIR, viewBuilders: [any RuntimeViewBuilder] = []) {
        let builders: [any RuntimeViewBuilder] = [
            TextRuntimeViewBuilder(),
            VStackRuntimeViewBuilder(),
            ForEachRuntimeViewBuilder(),
            ButtonRuntimeViewBuilder(),
        ] + viewBuilders
        for builder in builders {
            define(builder.typeName, value: .viewBuilder(builder))
        }
        let statementInterpreter = StatementInterpreter(scope: self)
        let values = try? statementInterpreter.executeAndCollectRuntimeViews(statements: ir.statements)
        self.runtimeViews = values ??  []
    }

    @MainActor
    public func makeTopLevelSwiftUIViews() throws -> AnyView {
        guard !runtimeViews.isEmpty else {
            throw RuntimeError.invalidViewResult("Top-level statements did not produce any SwiftUI views")
        }

        let swiftUIViews = try runtimeViews.map { runtimeView in
            try runtimeView.makeSwiftUIView()
        }

        return AnyView(ForEach(Array(swiftUIViews.enumerated()), id: \.0) { _, view in
            view
        })
    }
}
