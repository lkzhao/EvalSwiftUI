import Foundation
import SwiftUI
import EvalSwiftIR

public final class RuntimeModule: RuntimeScope {
    public var storage: RuntimeScopeStorage = [:]
    public var topLevelValues: [RuntimeValue] = []
    private var modifierBuilders: [String: RuntimeModifierBuilder] = [:]

    public convenience init(
        source: String,
        valueBuilders: [RuntimeValueBuilder] = [],
        modifierBuilders: [RuntimeModifierBuilder] = []
    ) throws {
        try self.init(
            ir: SwiftIRParser().parseModule(source: source),
            valueBuilders: valueBuilders,
            modifierBuilders: modifierBuilders
        )
    }

    public init(
        ir: ModuleIR,
        valueBuilders: [RuntimeValueBuilder] = [],
        modifierBuilders: [RuntimeModifierBuilder] = []
    ) throws {
        let builders: [RuntimeValueBuilder] = [
            IntValueBuilder(),
            FloatValueBuilder(name: "Float"),
            FloatValueBuilder(name: "Double"),
            FloatValueBuilder(name: "CGFloat"),
            ImageScaleValueBuilder(),
            ImageValueBuilder(),
            TextValueBuilder(),
            ButtonValueBuilder(),
            ToggleValueBuilder(),
            VStackValueBuilder(),
            HStackValueBuilder(),
            ZStackValueBuilder(),
            ForEachValueBuilder(),
            ColorValueBuilder(),
            ShapeStyleValueBuilder(),
            FontValueBuilder(),
            AlignmentValueBuilder(),
            HorizontalAlignmentValueBuilder(),
            VerticalAlignmentValueBuilder(),
            RoundedCornerStyleValueBuilder(),
            RoundedRectangleValueBuilder(),
            CircleValueBuilder(),
            RectangleValueBuilder(),
            CapsuleValueBuilder(),
            UUIDValueBuilder(),
            DateValueBuilder(),
        ] + valueBuilders
        for builder in builders {
            define(builder.name, value: .type(RuntimeType(builder: builder, parent: self)))
        }

        let modifierBuilderList: [RuntimeModifierBuilder] = [
            PaddingModifierBuilder(),
            BackgroundModifierBuilder(),
            OverlayModifierBuilder(),
            FontModifierBuilder(),
            ForegroundStyleModifierBuilder(),
            FrameModifierBuilder(),
            ImageScaleModifierBuilder(),
            OpacityModifierBuilder(),
            ShadowModifierBuilder(),
        ] + modifierBuilders
        for modifier in modifierBuilderList {
            self.modifierBuilders[modifier.name] = modifier
        }

        let statementInterpreter = StatementInterpreter(scope: self)
        let values = try statementInterpreter.executeAndCollectTopLevelValues(statements: ir.statements)
        self.topLevelValues = values
    }

    func modifierBuilder(named name: String) -> RuntimeModifierBuilder? {
        modifierBuilders[name]
    }

    @MainActor
    public func makeTopLevelSwiftUIViews() throws -> AnyView {
        guard !topLevelValues.isEmpty else {
            throw RuntimeError.invalidViewResult("Top-level statements did not produce any SwiftUI views")
        }

        let swiftUIViews = topLevelValues.compactMap {
            $0.asSwiftUIView
        }

        return AnyView(ForEach(Array(swiftUIViews.enumerated()), id: \.0) { _, view in
            view
        })
    }
}
