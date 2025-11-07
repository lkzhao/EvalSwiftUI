import SwiftUI

struct ImageScaleModifierBuilder: SwiftUIModifierBuilder {
    let name = "imageScale"

    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView {
        guard let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("imageScale requires one argument.")
        }

        let scale = try decodeScale(from: argument.value)
        return AnyView(base.imageScale(scale))
    }

    private func decodeScale(from value: SwiftValue) throws -> Image.Scale {
        guard case let .memberAccess(path) = value,
              let last = path.last else {
            throw SwiftUIEvaluatorError.invalidArguments("imageScale expects a member like .small/.medium/.large.")
        }

        switch last {
        case "small": return .small
        case "medium": return .medium
        case "large": return .large
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported image scale \(last).")
        }
    }
}
