import SwiftUI

struct ImageScaleModifierHandler: MemberFunctionHandler {
    let name = "imageScale"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseView = baseValue?.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("imageScale modifier requires a view receiver.")
        }
        guard let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("imageScale requires one argument.")
        }

        let scale = try decodeScale(from: argument.value)
        return .view(AnyView(baseView.imageScale(scale)))
    }

    private func decodeScale(from value: SwiftValue) throws -> Image.Scale {
        guard case let .memberAccess(path) = value.payload,
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
