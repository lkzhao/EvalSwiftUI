import SwiftUI

public struct ShadowModifierBuilder: RuntimeModifierBuilder {
    public let modifierName = "shadow"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var color: Color = Color.black.opacity(0.33)
        var radius: CGFloat?
        var x: CGFloat = 0
        var y: CGFloat = 0
        var positionalIndex = 0

        for argument in arguments {
            if let label = argument.label {
                switch label {
                case "color":
                    guard let colorValue = argument.value.asColor else {
                        throw RuntimeError.invalidViewArgument("color expects a Color value.")
                    }
                    color = colorValue
                case "radius":
                    radius = try ShadowModifierBuilder.cgFloat(from: argument, name: "radius")
                case "x":
                    x = try ShadowModifierBuilder.cgFloat(from: argument, name: "x")
                case "y":
                    y = try ShadowModifierBuilder.cgFloat(from: argument, name: "y")
                default:
                    continue
                }
                continue
            }

            switch positionalIndex {
            case 0:
                radius = try ShadowModifierBuilder.cgFloat(from: argument, name: "radius")
            case 1:
                x = try ShadowModifierBuilder.cgFloat(from: argument, name: "x")
            case 2:
                y = try ShadowModifierBuilder.cgFloat(from: argument, name: "y")
            default:
                break
            }
            positionalIndex += 1
        }

        guard let radius else {
            throw RuntimeError.invalidViewArgument("shadow modifier requires a radius argument.")
        }

        return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
    }
}

private extension ShadowModifierBuilder {
    static func cgFloat(from argument: RuntimeArgument, name: String) throws -> CGFloat {
        guard let value = argument.value.asDouble else {
            throw RuntimeError.invalidViewArgument("\(name) expects a numeric value.")
        }
        return CGFloat(value)
    }
}
