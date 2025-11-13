import SwiftUI

public struct CornerRadiusModifierBuilder: RuntimeModifierBuilder {
    public let modifierName = "cornerRadius"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard !arguments.isEmpty else {
            throw RuntimeError.invalidViewArgument("cornerRadius expects at least a radius value.")
        }

        var radiusArgument: RuntimeArgument?
        var antialiased: Bool = true

        for argument in arguments {
            if argument.label == "antialiased" {
                guard let flag = argument.value.asBool else {
                    throw RuntimeError.invalidViewArgument("antialiased expects a Boolean value.")
                }
                antialiased = flag
                continue
            }

            if radiusArgument == nil {
                radiusArgument = argument
            }
        }

        guard let radiusArgument else {
            throw RuntimeError.invalidViewArgument("cornerRadius requires a radius parameter.")
        }

        guard let radiusValue = radiusArgument.value.asDouble else {
            throw RuntimeError.invalidViewArgument("cornerRadius requires a numeric radius.")
        }
        return AnyView(view.cornerRadius(CGFloat(radiusValue), antialiased: antialiased))
    }
}
