import Foundation
import SwiftUI
import EvalSwiftIR

public final class RuntimeModule: RuntimeScope {
    public var storage: RuntimeScopeStorage = [:]
    public var runtimeViews: [RuntimeInstance] = []
    private var modifierBuilders: [String: RuntimeModifierBuilder] = [:]

    public convenience init(
        source: String,
        viewBuilders: [RuntimeValueBuilder] = [],
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
        viewBuilders: [RuntimeValueBuilder] = [],
        modifierBuilders: [RuntimeModifierBuilder] = []
    ) {
//        let builders: [RuntimeViewBuilder] = [
//            TextRuntimeViewBuilder(),
//            ImageRuntimeViewBuilder(),
//            VStackRuntimeViewBuilder(),
//            HStackRuntimeViewBuilder(),
//            ZStackViewBuilder(),
//            ForEachRuntimeViewBuilder(),
//            ButtonViewBuilder(),
//            CircleViewBuilder(),
//            RectangleViewBuilder(),
//            RoundedRectangleViewBuilder(),
//            ScrollViewViewBuilder(),
//            SpacerViewBuilder(),
//            ToggleViewBuilder(),
//        ] + viewBuilders
//        for builder in builders {
//            define(builder.typeName, value: .type(RuntimeType(builder: builder, parent: self)))
//        }
//
//        let modifiers: [RuntimeModifierBuilder] = [
//            PaddingModifierBuilder(),
//            BackgroundModifierBuilder(),
//            CornerRadiusModifierBuilder(),
//            FontModifierBuilder(),
//            ForegroundStyleModifierBuilder(),
//            FrameModifierBuilder(),
//            ImageScaleModifierBuilder(),
//            OpacityModifierBuilder(),
//            OverlayModifierBuilder(),
//            ShadowModifierBuilder(),
//        ] + modifierBuilders
//        for modifier in modifiers {
//            self.modifierBuilders[modifier.name] = modifier
//        }

//        SwiftUIRuntimeConstants.register(in: self)

        let imageBuilder = ImageRuntimeViewBuilder()
        define(imageBuilder.name, value: .type(RuntimeType(builder: imageBuilder, parent: self)))

        let statementInterpreter = StatementInterpreter(scope: self)
        let values = try? statementInterpreter.executeAndCollectRuntimeViews(statements: ir.statements)
        self.runtimeViews = values ?? []
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
