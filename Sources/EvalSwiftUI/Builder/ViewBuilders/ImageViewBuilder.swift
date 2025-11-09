import SwiftUI

struct ImageViewBuilder: SwiftUIViewBuilder {
    let name = "Image"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let argument = arguments.first,
              case let .string(value) = argument.value.payload else {
            throw SwiftUIEvaluatorError.invalidArguments("Image expects a string literal argument.")
        }

        switch argument.label {
        case "systemName":
            return AnyView(Image(systemName: value))
        case .none:
            return AnyView(Image(value))
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Unsupported Image argument label \(argument.label ?? "nil").")
        }
    }
}
