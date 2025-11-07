import SwiftUI

final class ViewRegistry {
    private typealias Builder = ([ResolvedArgument]) throws -> AnyView
    private var builders: [String: Builder]
    private let expressionResolver: ExpressionResolver

    init(expressionResolver: ExpressionResolver) {
        self.expressionResolver = expressionResolver
        builders = [
            "Text": { arguments in
                guard let first = arguments.first,
                      case let .string(value) = first.value else {
                    throw SwiftUIEvaluatorError.invalidArguments("Text expects a leading string literal.")
                }
                return AnyView(Text(value))
            },
        ]
    }

    func makeView(from constructor: ViewConstructor) throws -> AnyView {
        guard let builder = builders[constructor.name] else {
            throw SwiftUIEvaluatorError.unknownView(constructor.name)
        }

        let arguments = try expressionResolver.resolveArguments(constructor.arguments)
        return try builder(arguments)
    }
}
