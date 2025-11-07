import SwiftUI

final class ModifierRegistry {
    private typealias ModifierBuilder = ([ResolvedArgument], AnyView) throws -> AnyView
    private var builders: [String: ModifierBuilder]
    private let expressionResolver: ExpressionResolver

    init(expressionResolver: ExpressionResolver) {
        self.expressionResolver = expressionResolver
        builders = [
            "font": { arguments, base in
                guard let argument = arguments.first else {
                    throw SwiftUIEvaluatorError.invalidArguments("font modifier expects a Font value.")
                }
                let font = try Self.font(from: argument.value)
                return AnyView(base.font(font))
            },
            "padding": { arguments, base in
                guard arguments.isEmpty else {
                    throw SwiftUIEvaluatorError.unsupportedModifier("padding")
                }
                return AnyView(base.padding())
            },
        ]
    }

    func applyModifier(_ modifier: ModifierNode, to base: AnyView) throws -> AnyView {
        guard let builder = builders[modifier.name] else {
            throw SwiftUIEvaluatorError.unsupportedModifier(modifier.name)
        }

        let arguments = try expressionResolver.resolveArguments(modifier.arguments)
        return try builder(arguments, base)
    }

    private static func font(from value: SwiftValue) throws -> Font {
        guard case let .memberAccess(path) = value else {
            throw SwiftUIEvaluatorError.invalidArguments("font modifier expects a Font value.")
        }

        if path == ["title"] || path == ["Font", "title"] {
            return .title
        }

        throw SwiftUIEvaluatorError.invalidArguments("Unsupported font: \(path.joined(separator: "."))")
    }
}
