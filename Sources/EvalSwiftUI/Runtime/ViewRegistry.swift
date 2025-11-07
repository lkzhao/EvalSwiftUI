import SwiftUI

final class ViewRegistry {
    private var builders: [String: any SwiftUIViewBuilder]
    private let expressionResolver: ExpressionResolver

    init(expressionResolver: ExpressionResolver,
         additionalBuilders: [any SwiftUIViewBuilder] = []) {
        self.expressionResolver = expressionResolver
        builders = Self.makeLookup(
            defaults: Self.defaultBuilders,
            additional: additionalBuilders
        )
    }

    func makeView(from constructor: ViewConstructor) throws -> AnyView {
        guard let builder = builders[constructor.name] else {
            throw SwiftUIEvaluatorError.unknownView(constructor.name)
        }

        let arguments = try expressionResolver.resolveArguments(constructor.arguments)
        return try builder.makeView(arguments: arguments)
    }

    private static var defaultBuilders: [any SwiftUIViewBuilder] {
        [TextViewBuilder()]
    }

    private static func makeLookup(defaults: [any SwiftUIViewBuilder],
                                   additional: [any SwiftUIViewBuilder]) -> [String: any SwiftUIViewBuilder] {
        var lookup: [String: any SwiftUIViewBuilder] = [:]
        for builder in defaults + additional {
            lookup[builder.name] = builder
        }
        return lookup
    }
}
