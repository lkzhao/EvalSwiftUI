import SwiftUI

public struct CircleValueBuilder: RuntimeValueBuilder {
    public let name = "Circle"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(parameters: []) { _, _ in
                .swiftUI(.shape(AnyShape(Circle())))
            }
        ]
    }
}
