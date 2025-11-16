import SwiftUI

public struct AnyTransitionValueBuilder: RuntimeValueBuilder {
    public let name = "AnyTransition"
    public let definitions: [RuntimeBuilderDefinition] = []

    public init() {}

    public func populate(type: RuntimeType) {
        let transitions: [(String, String)] = [
            ("identity", "identity"),
            ("opacity", "opacity"),
            ("scale", "scale"),
            ("slide", "slide")
        ]

        for (name, token) in transitions {
            type.define(name, value: .string(token))
        }
    }
}
