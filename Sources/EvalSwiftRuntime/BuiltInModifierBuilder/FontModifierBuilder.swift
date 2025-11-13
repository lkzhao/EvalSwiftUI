import SwiftUI

public struct FontModifierBuilder: RuntimeModifierBuilder {
    public let modifierName = "font"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard let argument = arguments.first else {
            throw RuntimeError.invalidViewArgument("font modifier expects a Font argument.")
        }

        if let font = argument.value.asFont {
            return AnyView(view.font(font))
        }

        if let size = argument.value.asDouble {
            return AnyView(view.font(.system(size: CGFloat(size))))
        }

        throw RuntimeError.invalidViewArgument("font modifier expects a Font or numeric size argument.")
    }
}
