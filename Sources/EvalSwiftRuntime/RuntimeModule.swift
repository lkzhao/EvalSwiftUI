import Foundation
import SwiftUI
import EvalSwiftIR

public final class RuntimeModule: RuntimeScope {
    public var storage: [String: RuntimeValue] = [:]
    public var runtimeViews: [RuntimeInstance] = []
    private var registeredModifierBuilders: [String: any RuntimeViewModifierBuilder] = [:]

    public convenience init(
        source: String,
        viewBuilders: [any RuntimeViewBuilder] = [],
        modifierBuilders: [any RuntimeViewModifierBuilder] = []
    ) {
        self.init(
            ir: SwiftIRParser().parseModule(source: source),
            viewBuilders: viewBuilders,
            modifierBuilders: modifierBuilders
        )
    }

    public init(
        ir: ModuleIR,
        viewBuilders: [any RuntimeViewBuilder] = [],
        modifierBuilders: [any RuntimeViewModifierBuilder] = []
    ) {
        let builders: [any RuntimeViewBuilder] = [
            TextRuntimeViewBuilder(),
            ImageRuntimeViewBuilder(),
            VStackRuntimeViewBuilder(),
            HStackRuntimeViewBuilder(),
            ForEachRuntimeViewBuilder(),
            ButtonRuntimeViewBuilder(),
        ] + viewBuilders
        for builder in builders {
            define(builder.typeName, value: .viewBuilder(builder))
        }

        let modifiers: [any RuntimeViewModifierBuilder] = [
            PaddingRuntimeViewModifierBuilder(),
        ] + modifierBuilders
        for modifier in modifiers {
            registeredModifierBuilders[modifier.modifierName] = modifier
        }

        let statementInterpreter = StatementInterpreter(scope: self)
        let values = try? statementInterpreter.executeAndCollectRuntimeViews(statements: ir.statements)
        self.runtimeViews = values ?? []
    }

    func modifierBuilder(named name: String) -> (any RuntimeViewModifierBuilder)? {
        registeredModifierBuilders[name]
    }

    @MainActor
    public func makeTopLevelSwiftUIViews() throws -> AnyView {
        guard !runtimeViews.isEmpty else {
            throw RuntimeError.invalidViewResult("Top-level statements did not produce any SwiftUI views")
        }

        let swiftUIViews = try runtimeViews.map {
            try $0.makeSwiftUIView()
        }

        return AnyView(ForEach(Array(swiftUIViews.enumerated()), id: \.0) { _, view in
            view
        })
    }
}
