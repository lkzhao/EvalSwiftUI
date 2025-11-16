import SwiftUI

public struct FontValueBuilder: RuntimeValueBuilder {
    public let name = "Font"
    public let definitions: [RuntimeBuilderDefinition]

    private static let namedFonts: [(String, Font)] = [
        ("largeTitle", .largeTitle),
        ("title", .title),
        ("title2", .title2),
        ("title3", .title3),
        ("headline", .headline),
        ("subheadline", .subheadline),
        ("body", .body),
        ("callout", .callout),
        ("caption", .caption),
        ("caption2", .caption2),
        ("footnote", .footnote)
    ]

    public init() {
        self.definitions = []
    }

    public func populate(type: RuntimeType) {
        for (name, font) in Self.namedFonts {
            type.define(name, value: .swiftUI(.font(font)))
        }
    }
}
