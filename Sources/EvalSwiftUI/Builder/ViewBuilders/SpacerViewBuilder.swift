import SwiftUI

struct SpacerViewBuilder: SwiftUIViewBuilder {
    let name = "Spacer"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard arguments.count <= 1 else {
            throw SwiftUIEvaluatorError.invalidArguments("Spacer supports at most one minLength argument.")
        }

        let minLength = try arguments.first.map { argument in
            if let label = argument.label, label != "minLength" {
                throw SwiftUIEvaluatorError.invalidArguments("Unsupported Spacer argument label \(label).")
            }
            return try decodeLength(from: argument.value)
        }

        if let minLength {
            return AnyView(Spacer(minLength: minLength))
        }

        return AnyView(Spacer())
    }

    private func decodeLength(from value: SwiftValue) throws -> CGFloat? {
        guard case let .number(number) = value else {
            throw SwiftUIEvaluatorError.invalidArguments("Spacer minLength expects a numeric literal.")
        }
        return CGFloat(number)
    }
}
