import SwiftUI

public struct OpacityModifierBuilder: RuntimeModifierBuilder {
    public let modifierName = "opacity"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard let argument = arguments.first,
              let amount = argument.value.asDouble else {
            throw RuntimeError.invalidViewArgument("opacity expects a numeric amount.")
        }

        let clamped = max(0, min(1, amount))
        return AnyView(view.opacity(clamped))
    }
}
