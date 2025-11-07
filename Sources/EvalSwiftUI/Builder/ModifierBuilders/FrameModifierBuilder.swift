import SwiftUI

struct FrameModifierBuilder: SwiftUIModifierBuilder {
    let name = "frame"

    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView {
        var width: CGFloat?
        var height: CGFloat?
        var minWidth: CGFloat?
        var idealWidth: CGFloat?
        var maxWidth: CGFloat?
        var minHeight: CGFloat?
        var idealHeight: CGFloat?
        var maxHeight: CGFloat?
        var alignment: Alignment = .center
        var usesFlexibleSignature = false

        for argument in arguments {
            switch argument.label {
            case "width":
                width = try decodeDimension(from: argument.value)
            case "height":
                height = try decodeDimension(from: argument.value)
            case "minWidth":
                minWidth = try decodeDimension(from: argument.value)
                usesFlexibleSignature = true
            case "idealWidth":
                idealWidth = try decodeDimension(from: argument.value)
                usesFlexibleSignature = true
            case "maxWidth":
                maxWidth = try decodeDimension(from: argument.value)
                usesFlexibleSignature = true
            case "minHeight":
                minHeight = try decodeDimension(from: argument.value)
                usesFlexibleSignature = true
            case "idealHeight":
                idealHeight = try decodeDimension(from: argument.value)
                usesFlexibleSignature = true
            case "maxHeight":
                maxHeight = try decodeDimension(from: argument.value)
                usesFlexibleSignature = true
            case "alignment":
                alignment = try decodeAlignment(from: argument.value)
            case nil:
                // Allow unlabeled numbers for backwards compatibility (width, height order)
                if width == nil {
                    width = try decodeDimension(from: argument.value)
                } else if height == nil {
                    height = try decodeDimension(from: argument.value)
                } else {
                    throw SwiftUIEvaluatorError.invalidArguments("Too many unlabeled frame arguments.")
                }
            default:
                throw SwiftUIEvaluatorError.invalidArguments("Unsupported frame argument label \(argument.label ?? "").")
            }
        }

        if usesFlexibleSignature {
            return AnyView(
                base.frame(
                    minWidth: minWidth,
                    idealWidth: idealWidth,
                    maxWidth: maxWidth,
                    minHeight: minHeight,
                    idealHeight: idealHeight,
                    maxHeight: maxHeight,
                    alignment: alignment
                )
            )
        } else {
            return AnyView(base.frame(width: width, height: height, alignment: alignment))
        }
    }

    private func decodeDimension(from value: SwiftValue) throws -> CGFloat? {
        switch value {
        case let .number(number):
            return CGFloat(number)
        case let .memberAccess(path):
            if let last = path.last, last.compare("infinity", options: .caseInsensitive) == .orderedSame {
                return .infinity
            }
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported dimension value \(path.joined(separator: "."))")
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Frame dimensions must be numeric or .infinity.")
        }
    }

    private func decodeAlignment(from value: SwiftValue) throws -> Alignment {
        guard case let .memberAccess(path) = value, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("Alignment must be an Alignment member.")
        }

        switch last.lowercased() {
        case "center": return .center
        case "leading": return .leading
        case "trailing": return .trailing
        case "top": return .top
        case "bottom": return .bottom
        case "topleading": return .topLeading
        case "toptrailing": return .topTrailing
        case "bottomleading": return .bottomLeading
        case "bottomtrailing": return .bottomTrailing
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported alignment \(last).")
        }
    }
}
