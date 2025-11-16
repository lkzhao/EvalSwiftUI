import SwiftUI

public struct RoundedCornerStyleValueBuilder: RuntimeValueBuilder {
    public let name = "RoundedCornerStyle"
    public let definitions: [RuntimeBuilderDefinition]

    private static let styles: [(String, RoundedCornerStyle)] = [
        ("circular", .circular),
        ("continuous", .continuous)
    ]

    public init() {
        self.definitions = []
    }

    public func populate(type: RuntimeType) {
        for (name, style) in Self.styles {
            type.define(name, value: .swiftUI(.roundedCornerStyle(style)))
        }
    }
}
