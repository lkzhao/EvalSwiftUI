import SwiftUI

final class ModifierRegistry {
    private var builders: [String: any SwiftUIModifierBuilder]

    init(additionalBuilders: [any SwiftUIModifierBuilder] = []) {
        builders = Self.makeLookup(
            defaults: Self.defaultBuilders,
            additional: additionalBuilders
        )
    }

    func applyModifier(_ modifier: ModifierNode,
                       arguments: [ResolvedArgument],
                       to base: AnyView) throws -> AnyView {
        guard let builder = builders[modifier.name] else {
            throw SwiftUIEvaluatorError.unsupportedModifier(modifier.name)
        }

        return try builder.apply(arguments: arguments, to: base)
    }

    private static var defaultBuilders: [any SwiftUIModifierBuilder] {
        [FontModifierBuilder(), PaddingModifierBuilder()]
    }

    private static func makeLookup(defaults: [any SwiftUIModifierBuilder],
                                   additional: [any SwiftUIModifierBuilder]) -> [String: any SwiftUIModifierBuilder] {
        var lookup: [String: any SwiftUIModifierBuilder] = [:]
        for builder in defaults + additional {
            lookup[builder.name] = builder
        }
        return lookup
    }
}
