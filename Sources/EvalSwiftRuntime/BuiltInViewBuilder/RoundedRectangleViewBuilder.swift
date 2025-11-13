import SwiftUI

public struct RoundedRectangleViewBuilder: RuntimeViewBuilder {
    public let typeName = "RoundedRectangle"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var cornerRadius: CGFloat?
        var style: RoundedCornerStyle = .continuous
        var positionalIndex = 0

        for argument in arguments {
            if let label = argument.label {
                switch label {
                case "cornerRadius":
                    cornerRadius = try resolveCornerRadius(from: argument.value, label: "cornerRadius")
                case "style":
                    style = try resolveStyle(from: argument.value)
                default:
                    throw RuntimeError.invalidViewArgument("RoundedRectangle only supports cornerRadius and style arguments.")
                }
                continue
            }

            if positionalIndex == 0 {
                cornerRadius = try resolveCornerRadius(from: argument.value, label: "cornerRadius")
            } else if positionalIndex == 1 {
                style = try resolveStyle(from: argument.value)
            } else {
                throw RuntimeError.invalidViewArgument("RoundedRectangle received unexpected positional arguments.")
            }
            positionalIndex += 1
        }

        guard let cornerRadius else {
            throw RuntimeError.invalidViewArgument("RoundedRectangle requires a cornerRadius argument.")
        }

        return AnyView(RoundedRectangle(cornerRadius: cornerRadius, style: style))
    }

    private func resolveCornerRadius(from value: RuntimeValue, label: String) throws -> CGFloat {
        guard let numericValue = value.asDouble else {
            throw RuntimeError.invalidViewArgument("\(label) must be convertible to a number.")
        }
        return CGFloat(numericValue)
    }

    private func resolveStyle(from value: RuntimeValue) throws -> RoundedCornerStyle {
        guard let style = value.asRoundedCornerStyle else {
            throw RuntimeError.invalidViewArgument("style must be a RoundedCornerStyle value.")
        }
        return style
    }
}
