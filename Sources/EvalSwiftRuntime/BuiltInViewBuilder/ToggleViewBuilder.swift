import SwiftUI

public struct ToggleViewBuilder: RuntimeViewBuilder {
    public let typeName = "Toggle"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var isOnValue: Bool?
        var title: String?
        var labelView: AnyView?

        for argument in arguments {
            if let label = argument.label {
                switch label {
                case "isOn":
                    isOnValue = try resolveIsOn(from: argument.value)
                case "label":
                    labelView = try resolveLabelView(from: argument.value)
                default:
                    labelView = labelView ?? (try? resolveLabelView(from: argument.value))
                }
                continue
            }

            if title == nil, case .string(let string) = argument.value {
                title = string
                continue
            }

            if labelView == nil, let view = try? resolveLabelView(from: argument.value) {
                labelView = view
                continue
            }

            if isOnValue == nil, let boolValue = argument.value.asBool {
                isOnValue = boolValue
            }
        }

        guard let resolvedIsOn = isOnValue else {
            throw RuntimeError.invalidViewArgument("Toggle requires an isOn Bool value.")
        }

        let binding = Binding.constant(resolvedIsOn)

        if let labelView {
            return AnyView(Toggle(isOn: binding) {
                labelView
            })
        }

        guard let title else {
            throw RuntimeError.invalidViewArgument("Toggle requires a title string or label closure.")
        }

        return AnyView(Toggle(title, isOn: binding))
    }

    private func resolveIsOn(from value: RuntimeValue) throws -> Bool {
        guard let boolValue = value.asBool else {
            throw RuntimeError.invalidViewArgument("Toggle isOn arguments must be Bool values.")
        }
        return boolValue
    }

    @MainActor
    private func resolveLabelView(from value: RuntimeValue) throws -> AnyView {
        guard let view = value.asSwiftUIView else {
            throw RuntimeError.invalidViewArgument("Toggle labels must be SwiftUI views.")
        }
        return view
    }
}
