import SwiftUI

public struct ImageScaleValueBuilder: RuntimeValueBuilder {
    public let name = "Image.Scale"
    public let definitions: [RuntimeBuilderDefinition]

    private static let scales: [(String, Image.Scale)] = [
        ("small", .small),
        ("medium", .medium),
        ("large", .large)
    ]

    public init() {
        self.definitions = []
    }

    public func populate(type: RuntimeType) {
        for (name, scale) in Self.scales {
            type.define(name, value: .swiftUI(.imageScale(scale)))
        }
    }
}
