import SwiftUI

public struct ImageScaleModifierBuilder: RuntimeModifierBuilder {
    public let modifierName = "imageScale"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard let argument = arguments.first else {
            throw RuntimeError.invalidViewArgument("imageScale expects an Image.Scale argument.")
        }

        guard let scale = argument.value.asImageScale else {
            throw RuntimeError.invalidViewArgument("imageScale expects an Image.Scale argument.")
        }
        return AnyView(view.imageScale(scale))
    }
}
