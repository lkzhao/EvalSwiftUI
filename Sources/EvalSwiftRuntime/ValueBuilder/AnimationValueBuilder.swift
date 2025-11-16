import SwiftUI

public struct AnimationValueBuilder: RuntimeValueBuilder {
    public let name = "Animation"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: []
            ) { _, _ in .swiftUI(.animation(.default)) }
        ]
    }

    public func populate(type: RuntimeType) {
        type.define("default", value: .swiftUI(.animation(.default)))
        type.define("easeInOut", value: .swiftUI(.animation(.easeInOut)))
        type.define("easeIn", value: .swiftUI(.animation(.easeIn)))
        type.define("easeOut", value: .swiftUI(.animation(.easeOut)))
        type.define("linear", value: .swiftUI(.animation(.linear)))
    }
}
