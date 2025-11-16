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
                guard let binding = arguments.value(named: "binding")?.asBinding else {
                    throw RuntimeError.invalidArgument("focused(_:equals:) requires a binding receiver.")
                }
                let equalsValue = try FocusedModifierBuilder.equalsHashable(from: arguments.value(named: "equals"))
                return AnyView(
                    view.modifier(
                        RuntimeFocusedModifier(binding: binding, equalsValue: equalsValue)
                    )
                )
            }
        )
    ]

    private static func equalsHashable(from value: RuntimeValue?) throws -> AnyHashable? {
        guard let value, !value.isNil else {
            return nil
        }
        guard let hashable = value.asAnyHashable else {
            throw RuntimeError.invalidArgument("focused(_:equals:) expects a Hashable value for 'equals'.")
        }
        return hashable
    }
}

struct OnSubmitModifierBuilder: RuntimeModifierBuilder {
    let name = "onSubmit"
    let definitions: [RuntimeModifierDefinition] = [
        RuntimeViewModifierDefinition(
            parameters: [RuntimeParameter(label: "_", name: "action", type: "() -> Void")]
        ) { view, arguments, _ in
            guard let function = arguments.value(named: "action")?.asFunction else {
                throw RuntimeError.invalidArgument("onSubmit requires an action closure.")
            }
            return AnyView(view.onSubmit {
                do {
                    _ = try function.invoke()
                } catch {
                    assertionFailure("onSubmit action failed: \(error)")
                }
            })
        }
    ]
}

private struct RuntimeFocusedModifier: ViewModifier {
    @FocusState private var focusValue: AnyHashable?

    let binding: RuntimeBinding
    let equalsValue: AnyHashable?

    func body(content: Content) -> some View {
        let runtimeValue = readRuntimeValue()
        let normalizedRuntimeValue = normalize(runtimeValue)

        return content
            .focused($focusValue, equals: equalsValue)
            .onAppear {
                focusValue = normalizedRuntimeValue
            }
            .onChange(of: runtimeValue) { newValue in
                let normalized = normalize(newValue)
                if focusValue != normalized {
                    focusValue = normalized
                }
            }
            .onChange(of: focusValue) { newValue in
                let normalized = normalize(newValue)
                if readRuntimeValue() != normalized {
                    writeRuntimeValue(normalized)
                }
            }
    }

    private func readRuntimeValue() -> AnyHashable? {
        guard let value = try? binding.get(), !value.isNil else {
            return nil
        }
        return value.asAnyHashable
    }

    private func writeRuntimeValue(_ newValue: AnyHashable?) {
        do {
            try binding.set(RuntimeValue.from(anyHashable: newValue))
        } catch {
            assertionFailure("Failed to update focus binding: \(error)")
        }
    }

    private func normalize(_ candidate: AnyHashable?) -> AnyHashable? {
        guard let equalsValue else {
            return candidate
        }
        return candidate == equalsValue ? equalsValue : nil
    }
}
