import SwiftUI

struct FontModifierBuilder: SwiftUIModifierBuilder {
    let name = "font"

    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView {
        guard let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("font modifier expects a Font value.")
        }
        let font = try decodeFont(from: argument.value)
        return AnyView(base.font(font))
    }

    private func decodeFont(from value: SwiftValue) throws -> Font {
        guard case let .memberAccess(path) = value else {
            throw SwiftUIEvaluatorError.invalidArguments("font modifier expects a Font value.")
        }

        if path == ["title"] || path == ["Font", "title"] {
            return .title
        }

        throw SwiftUIEvaluatorError.invalidArguments("Unsupported font: \(path.joined(separator: "."))")
    }
}
