import SwiftUI

struct FontModifierHandler: MemberFunctionHandler {
    let name = "font"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseView = baseValue?.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("font modifier requires a view receiver.")
        }
        guard let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("font modifier expects a Font value.")
        }
        let font = try decodeFont(from: argument.value)
        return .view(AnyView(baseView.font(font)))
    }

    private func decodeFont(from value: SwiftValue) throws -> Font {
        switch value.payload {
        case let .memberAccess(path):
            return try decodePresetFont(path)
        case let .functionCall(call):
            return try decodeFontFunction(call)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("font modifier expects a Font value.")
        }
    }

    private func decodePresetFont(_ path: [String]) throws -> Font {
        guard let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported font path.")
        }

        switch last {
        case "largeTitle": return .largeTitle
        case "title": return .title
        case "title2": return .title2
        case "title3": return .title3
        case "headline": return .headline
        case "subheadline": return .subheadline
        case "body": return .body
        case "callout": return .callout
        case "footnote": return .footnote
        case "caption": return .caption
        case "caption2": return .caption2
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported font: \(path.joined(separator: "."))")
        }
    }

    private func decodeFontFunction(_ call: FunctionCallValue) throws -> Font {
        guard let name = call.name.last else {
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported font function call.")
        }

        switch name {
        case "system":
            return try decodeSystemFont(call.arguments)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported font function \(name).")
        }
    }

    private func decodeSystemFont(_ arguments: [ResolvedArgument]) throws -> Font {
        guard let sizeArgument = arguments.first(where: { $0.label == "size" || $0.label == nil }) else {
            throw SwiftUIEvaluatorError.invalidArguments("Font.system requires a size argument.")
        }

        let size = try number(from: sizeArgument.value)
        let weight = try arguments.first(where: { $0.label == "weight" }).map { try decodeWeight(from: $0.value) }
        let design = try arguments.first(where: { $0.label == "design" }).map { try decodeDesign(from: $0.value) }

        return Font.system(
            size: CGFloat(size),
            weight: weight ?? .regular,
            design: design ?? .default
        )
    }

    private func decodeWeight(from value: SwiftValue) throws -> Font.Weight {
        guard case let .memberAccess(path) = value.payload, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("Font weight expects a Font.Weight member.")
        }

        switch last {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported font weight \(last).")
        }
    }

    private func decodeDesign(from value: SwiftValue) throws -> Font.Design {
        guard case let .memberAccess(path) = value.payload, let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("Font design expects a Font.Design member.")
        }

        switch last {
        case "default": return .default
        case "serif": return .serif
        case "rounded": return .rounded
        case "monospaced": return .monospaced
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported font design \(last).")
        }
    }

    private func number(from value: SwiftValue) throws -> Double {
        guard case let .number(number) = value.payload else {
            throw SwiftUIEvaluatorError.invalidArguments("Expected numeric literal.")
        }
        return number
    }
}
