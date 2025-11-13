import SwiftUI

public struct PaddingRuntimeViewModifierBuilder: RuntimeViewModifierBuilder {
    public let modifierName = "padding"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard !arguments.isEmpty else {
            return AnyView(view.padding())
        }

        guard arguments.count == 1,
              let amount = arguments.first?.value.asDouble else {
            throw RuntimeError.invalidViewArgument("padding currently supports zero or one numeric argument.")
        }

        return AnyView(view.padding(CGFloat(amount)))
    }
}
