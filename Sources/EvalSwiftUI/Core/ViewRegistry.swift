import SwiftUI

final class ViewRegistry {
    private var builders: [String: any SwiftUIViewBuilder]

    init(additionalBuilders: [any SwiftUIViewBuilder] = []) {
        builders = Self.makeLookup(
            defaults: Self.defaultBuilders,
            additional: additionalBuilders
        )
    }

    func makeView(from constructor: ViewConstructor,
                  arguments: [ResolvedArgument]) throws -> AnyView {
        guard let builder = builders[constructor.name] else {
            throw SwiftUIEvaluatorError.unknownView(constructor.name)
        }

        return try builder.makeView(arguments: arguments)
    }

    private static var defaultBuilders: [any SwiftUIViewBuilder] {
        [TextViewBuilder(), VStackViewBuilder(), ImageViewBuilder()]
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
