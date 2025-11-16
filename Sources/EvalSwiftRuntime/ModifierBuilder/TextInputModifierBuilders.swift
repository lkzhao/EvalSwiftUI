import SwiftUI

struct KeyboardTypeModifierBuilder: RuntimeModifierBuilder {
    let name = "keyboardType"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "type", type: "UIKeyboardType")
            ],
            apply: { view, _, _ in AnyView(view) }
        )
    ]
}

struct TextContentTypeModifierBuilder: RuntimeModifierBuilder {
    let name = "textContentType"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "type", type: "UITextContentType", defaultValue: .void)
            ],
            apply: { view, _, _ in AnyView(view) }
        )
    ]
}

struct TextInputAutocapitalizationModifierBuilder: RuntimeModifierBuilder {
    let name = "textInputAutocapitalization"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "style", type: "TextInputAutocapitalization", defaultValue: .void)
            ],
            apply: { view, _, _ in AnyView(view) }
        )
    ]
}

struct AutocorrectionDisabledModifierBuilder: RuntimeModifierBuilder {
    let name = "autocorrectionDisabled"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(parameters: []) { view, _, _ in
            AnyView(view)
        },
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "value", type: "Bool")]
        ) { view, _, _ in
            AnyView(view)
        }
    ]
}

struct SubmitLabelModifierBuilder: RuntimeModifierBuilder {
    let name = "submitLabel"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "label", type: "SubmitLabel")
            ],
            apply: { view, _, _ in AnyView(view) }
        )
    ]
}

struct FocusedModifierBuilder: RuntimeModifierBuilder {
    let name = "focused"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [
                RuntimeParameter(label: "_", name: "binding", type: nil),
                RuntimeParameter(label: "equals", name: "equals", type: nil, defaultValue: .void)
            ],
            apply: { view, arguments, _ in
                guard arguments.value(named: "binding")?.asBinding != nil else {
                    throw RuntimeError.invalidArgument("focused(_:equals:) requires a binding receiver.")
                }
                return AnyView(view)
            }
        )
    ]
}

struct OnSubmitModifierBuilder: RuntimeModifierBuilder {
    let name = "onSubmit"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "action", type: "() -> Void")]
        ) { view, _, _ in
            AnyView(view)
        }
    ]
}
