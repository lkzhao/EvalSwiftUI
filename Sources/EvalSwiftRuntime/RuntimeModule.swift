import Foundation
import SwiftUI
import EvalSwiftIR

public final class RuntimeModule: RuntimeScope {
    public var storage: [String: RuntimeValue] = [:]
    public var runtimeViews: [RuntimeInstance] = []
    private var viewBuilders: [String: RuntimeViewBuilder] = [:]
    private var modifierBuilders: [String: RuntimeModifierBuilder] = [:]

    public convenience init(
        source: String,
        viewBuilders: [RuntimeViewBuilder] = [],
        modifierBuilders: [RuntimeModifierBuilder] = []
    ) {
        self.init(
            ir: SwiftIRParser().parseModule(source: source),
            viewBuilders: viewBuilders,
            modifierBuilders: modifierBuilders
        )
    }

    public init(
        ir: ModuleIR,
        viewBuilders: [RuntimeViewBuilder] = [],
        modifierBuilders: [RuntimeModifierBuilder] = []
    ) {
        let builders: [RuntimeViewBuilder] = [
            TextRuntimeViewBuilder(),
            ImageRuntimeViewBuilder(),
            VStackRuntimeViewBuilder(),
            HStackRuntimeViewBuilder(),
            ForEachRuntimeViewBuilder(),
            ButtonRuntimeViewBuilder(),
        ] + viewBuilders
        for builder in builders {
            self.viewBuilders[builder.typeName] = builder
        }

        let modifiers: [RuntimeModifierBuilder] = [
            PaddingModifierBuilder(),
            BackgroundModifierBuilder(),
            CornerRadiusModifierBuilder(),
            FontModifierBuilder(),
            ForegroundStyleModifierBuilder(),
            FrameModifierBuilder(),
            ImageScaleModifierBuilder(),
            OpacityModifierBuilder(),
            OverlayModifierBuilder(),
            ShadowModifierBuilder(),
        ] + modifierBuilders
        for modifier in modifiers {
            self.modifierBuilders[modifier.modifierName] = modifier
        }

        SwiftUIRuntimeConstants.register(in: self)

        let statementInterpreter = StatementInterpreter(scope: self)
        let values = try? statementInterpreter.executeAndCollectRuntimeViews(statements: ir.statements)
        self.runtimeViews = values ?? []
    }

    func viewBuilder(named name: String) -> RuntimeViewBuilder? {
        viewBuilders[name]
    }

    func modifierBuilder(named name: String) -> RuntimeModifierBuilder? {
        modifierBuilders[name]
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
