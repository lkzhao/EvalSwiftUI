import SwiftUI

public struct FrameModifierBuilder: RuntimeModifierBuilder {
    public let modifierName = "frame"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var width: CGFloat?
        var height: CGFloat?
        var minWidth: CGFloat?
        var idealWidth: CGFloat?
        var maxWidth: CGFloat?
        var minHeight: CGFloat?
        var idealHeight: CGFloat?
        var maxHeight: CGFloat?
        var alignment: Alignment = .center

        var positionalIndex = 0

        for argument in arguments {
            if let label = argument.label {
                switch label {
                case "width":
                    width = try requireCGFloat(argument, name: "width")
                case "height":
                    height = try requireCGFloat(argument, name: "height")
                case "minWidth":
                    minWidth = try requireCGFloat(argument, name: "minWidth")
                case "idealWidth":
                    idealWidth = try requireCGFloat(argument, name: "idealWidth")
                case "maxWidth":
                    maxWidth = try requireCGFloat(argument, name: "maxWidth")
                case "minHeight":
                    minHeight = try requireCGFloat(argument, name: "minHeight")
                case "idealHeight":
                    idealHeight = try requireCGFloat(argument, name: "idealHeight")
                case "maxHeight":
                    maxHeight = try requireCGFloat(argument, name: "maxHeight")
                case "alignment":
                    alignment = try requireAlignment(argument, name: "alignment")
                default:
                    continue
                }
                continue
            }

            if positionalIndex == 0 {
                width = try requirePositionalCGFloat(argument, name: "width")
            } else if positionalIndex == 1 {
                height = try requirePositionalCGFloat(argument, name: "height")
            }
            positionalIndex += 1
        }

        if width != nil || height != nil {
            return AnyView(view.frame(width: width, height: height, alignment: alignment))
        }

        let hasFlexibleSizing = [minWidth, idealWidth, maxWidth, minHeight, idealHeight, maxHeight]
            .contains { $0 != nil }

        if hasFlexibleSizing {
            return AnyView(
                view.frame(
                    minWidth: minWidth,
                    idealWidth: idealWidth,
                    maxWidth: maxWidth,
                    minHeight: minHeight,
                    idealHeight: idealHeight,
                    maxHeight: maxHeight,
                    alignment: alignment
                )
            )
        }

        throw RuntimeError.invalidViewArgument("frame modifier expects width/height or flexible sizing arguments.")
    }
}

private func requireCGFloat(_ argument: RuntimeArgument, name: String) throws -> CGFloat {
    guard let value = argument.value.asDouble else {
        throw RuntimeError.invalidViewArgument("\(name) expects a numeric value.")
    }
    return CGFloat(value)
}

private func requirePositionalCGFloat(_ argument: RuntimeArgument, name: String) throws -> CGFloat {
    guard let value = argument.value.asDouble else {
        throw RuntimeError.invalidViewArgument("\(name) expects a numeric value.")
    }
    return CGFloat(value)
}

private func requireAlignment(_ argument: RuntimeArgument, name: String) throws -> Alignment {
    guard let alignment = argument.value.asAlignment else {
        throw RuntimeError.invalidViewArgument("\(name) expects an Alignment value.")
    }
    return alignment
}
