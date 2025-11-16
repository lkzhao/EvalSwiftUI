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
            UnitPointValueBuilder(),
            AngleValueBuilder(),
            GradientValueBuilder(),
            LinearGradientValueBuilder(),
            RadialGradientValueBuilder(),
            AngularGradientValueBuilder(),
            ShapeStyleValueBuilder(),
            FillStyleValueBuilder(),
            FontValueBuilder(),
            AlignmentValueBuilder(),
            HorizontalAlignmentValueBuilder(),
            VerticalAlignmentValueBuilder(),
            BlendModeValueBuilder(),
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
        define("infinity", value: .double(Double.infinity))

        let modifierBuilderList: [RuntimeModifierBuilder] = [
            PaddingModifierBuilder(),
            BackgroundModifierBuilder(),
            BorderModifierBuilder(),
            ClipShapeModifierBuilder(),
            MaskModifierBuilder(),
            OverlayModifierBuilder(),
            FontModifierBuilder(),
            ForegroundStyleModifierBuilder(),
            FrameModifierBuilder(),
            ImageScaleModifierBuilder(),
            BlendModeModifierBuilder(),
            OpacityModifierBuilder(),
            ShadowModifierBuilder(),
            StringFunctionModifierBuilder.contains(),
            StringFunctionModifierBuilder.hasPrefix(),
            StringFunctionModifierBuilder.hasSuffix(),
            StringFunctionModifierBuilder.split(),
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

    func lookupImplicitMember(
        named name: String,
        expectedType: String?,
        visited: inout Set<ObjectIdentifier>
    ) -> RuntimeValue? {
        let identifier = ObjectIdentifier(self)
        guard visited.insert(identifier).inserted else { return nil }
        var bestValue: RuntimeValue?
        var bestPriority = Int.min
        if let holder = storage[name] {
            let candidates = holder.values.filter { $0.matches(expectedType: expectedType) }
            if let value = candidates.max(by: { $0.implicitPriority < $1.implicitPriority }) {
                bestValue = value
                bestPriority = value.implicitPriority
            }
        }
        for entry in storage.values {
            for stored in entry.values {
                if case .type(let type) = stored,
                   let nestedValue = type.lookupImplicitMember(
                       named: name,
                       expectedType: expectedType,
                       visited: &visited
                   ),
                   nestedValue.implicitPriority > bestPriority {
                    bestValue = nestedValue
                    bestPriority = nestedValue.implicitPriority
                }
            }
        }
        return bestValue
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
