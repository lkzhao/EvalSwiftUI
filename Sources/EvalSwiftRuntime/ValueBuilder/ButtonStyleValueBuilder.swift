import SwiftUI

public struct ButtonStyleConfigurationValueBuilder: RuntimeValueBuilder {
    public let name = "ButtonStyleConfiguration"
    public let definitions: [RuntimeBuilderDefinition] = []

    public init() {}

    public func populate(type: RuntimeType) {
        let styles = [
            "bordered",
            "borderedProminent",
            "plain"
        ]
        for style in styles {
            type.define(style, value: .string(style))
        }
    }
}
