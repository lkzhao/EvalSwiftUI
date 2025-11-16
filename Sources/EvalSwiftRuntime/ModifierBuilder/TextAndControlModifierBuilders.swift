import SwiftUI

struct TintModifierBuilder: RuntimeModifierBuilder {
    let name = "tint"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "style", type: "ShapeStyle")]
        ) { view, arguments, _ in
            guard let styleValue = arguments.value(named: "style") else {
                throw RuntimeError.invalidArgument("tint(_:) expects a style argument.")
            }
            if let color = styleValue.asColor {
                return AnyView(view.tint(color))
            }
            if let shapeStyle = styleValue.asShapeStyle {
                return AnyView(view.tint(shapeStyle))
            }
            throw RuntimeError.invalidArgument("Unsupported tint style.")
        }
    ]
}

struct DisabledModifierBuilder: RuntimeModifierBuilder {
    let name = "disabled"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "isDisabled", type: "Bool")]
        ) { view, arguments, _ in
            let disabled = arguments.value(named: "isDisabled")?.asBool ?? false
            return AnyView(view.disabled(disabled))
        }
    ]
}

struct BoldModifierBuilder: RuntimeModifierBuilder {
    let name = "bold"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(parameters: []) { view, _, _ in
            AnyView(view.bold())
        }
    ]
}

struct FontWeightModifierBuilder: RuntimeModifierBuilder {
    let name = "fontWeight"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "weight", type: "Font.Weight")]
        ) { view, arguments, _ in
            guard let weight = arguments.value(named: "weight")?.asFontWeight else {
                throw RuntimeError.invalidArgument("fontWeight(_:) expects a Font.Weight value.")
            }
            return AnyView(view.fontWeight(weight))
        }
    ]
}

struct MultilineTextAlignmentModifierBuilder: RuntimeModifierBuilder {
    let name = "multilineTextAlignment"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "alignment", type: "TextAlignment")]
        ) { view, arguments, _ in
            guard let alignment = arguments.value(named: "alignment")?.asTextAlignment else {
                throw RuntimeError.invalidArgument("multilineTextAlignment(_:) expects a TextAlignment value.")
            }
            return AnyView(view.multilineTextAlignment(alignment))
        }
    ]
}

struct ButtonStyleModifierBuilder: RuntimeModifierBuilder {
    let name = "buttonStyle"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "style", type: "ButtonStyleConfiguration")]
        ) { view, arguments, _ in
            guard let identifier = arguments.value(named: "style")?.asString else {
                throw RuntimeError.invalidArgument("buttonStyle(_:) expects a style identifier.")
            }
            return AnyView(ButtonStyleModifierBuilder.applyStyle(identifier: identifier, to: view))
        }
    ]

    private static func applyStyle(identifier: String, to view: AnyView) -> AnyView {
        switch identifier.lowercased() {
        case "bordered":
            return AnyView(view.buttonStyle(.bordered))
        case "borderedprominent":
            return AnyView(view.buttonStyle(.borderedProminent))
        case "plain":
            return AnyView(view.buttonStyle(.plain))
        default:
            return view
        }
    }
}

struct ContentShapeModifierBuilder: RuntimeModifierBuilder {
    let name = "contentShape"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "shape", type: "Shape")]
        ) { view, arguments, _ in
            guard let shape = arguments.value(named: "shape")?.asShape else {
                throw RuntimeError.invalidArgument("contentShape(_:) expects a shape argument.")
            }
            return AnyView(view.contentShape(shape))
        }
    ]
}

struct AccessibilityLabelModifierBuilder: RuntimeModifierBuilder {
    let name = "accessibilityLabel"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "label", type: "String")]
        ) { view, arguments, _ in
            guard let label = arguments.value(named: "label")?.asString else {
                throw RuntimeError.invalidArgument("accessibilityLabel(_:) expects a String.")
            }
            return AnyView(view.accessibilityLabel(Text(label)))
        }
    ]
}

struct AccessibilityHiddenModifierBuilder: RuntimeModifierBuilder {
    let name = "accessibilityHidden"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "hidden", type: "Bool")]
        ) { view, arguments, _ in
            let hidden = arguments.value(named: "hidden")?.asBool ?? false
            return AnyView(view.accessibilityHidden(hidden))
        }
    ]
}

struct AnimationModifierBuilder: RuntimeModifierBuilder {
    let name = "animation"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "animation", type: "Animation"),
                RuntimeParameter(label: "value", name: "value", type: nil, defaultValue: .void)
            ]
        ) { view, arguments, _ in
            // Evaluate arguments for validation but intentionally ignore their effect.
            _ = arguments.value(named: "animation")?.asAnimation
            _ = arguments.value(named: "value")?.asAnyHashable
            return AnyView(view)
        }
    ]
}

struct TransitionModifierBuilder: RuntimeModifierBuilder {
    let name = "transition"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "transition", type: "AnyTransition")
            ]
        ) { view, _, _ in
            // Accept transitions but render without applying them.
            AnyView(view)
        }
    ]
}

struct OnTapGestureModifierBuilder: RuntimeModifierBuilder {
    let name = "onTapGesture"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [
                RuntimeParameter(label: "count", name: "count", type: "Int", defaultValue: .int(1)),
                RuntimeParameter(label: "_", name: "perform", type: "() -> Void")
            ]
        ) { view, arguments, _ in
            let count = arguments.value(named: "count")?.asInt ?? 1
            guard let function = arguments.value(named: "perform")?.asFunction else {
                throw RuntimeError.invalidArgument("onTapGesture requires an action closure.")
            }
            return AnyView(view.onTapGesture(count: count) {
                do {
                    _ = try function.invoke()
                } catch {
                    assertionFailure("onTapGesture action failed: \(error)")
                }
            })
        }
    ]
}
