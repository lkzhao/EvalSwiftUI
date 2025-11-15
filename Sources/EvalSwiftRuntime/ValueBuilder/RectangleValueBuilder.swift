import SwiftUI

public struct RectangleValueBuilder: RuntimeValueBuilder {
    public let name = "Rectangle"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(parameters: []) { _, _ in
                .swiftUI(.shape(AnyShape(Rectangle())))
            }
        ]
    }
}
