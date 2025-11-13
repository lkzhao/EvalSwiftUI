import SwiftUI

public struct ForegroundStyleModifierBuilder: RuntimeModifierBuilder {
    public let modifierName = "foregroundStyle"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard let argument = arguments.first else {
            throw RuntimeError.invalidViewArgument("foregroundStyle expects a Color or ShapeStyle argument.")
        }

        guard let color = argument.value.asColor else {
            throw RuntimeError.invalidViewArgument("foregroundStyle expects a Color value.")
        }
        return AnyView(view.foregroundStyle(color))
    }
}
