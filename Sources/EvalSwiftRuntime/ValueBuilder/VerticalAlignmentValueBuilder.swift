import SwiftUI

public struct VerticalAlignmentValueBuilder: RuntimeValueBuilder {
    public let name = "VerticalAlignment"
    public let definitions: [RuntimeBuilderDefinition]

    private static let alignments: [(String, VerticalAlignment)] = [
        ("top", .top),
        ("center", .center),
        ("bottom", .bottom),
        ("firstTextBaseline", .firstTextBaseline),
        ("lastTextBaseline", .lastTextBaseline)
    ]

    public init() {
        self.definitions = []
    }

    public func populate(type: RuntimeType) {
        for (name, alignment) in Self.alignments {
            type.define(name, value: .swiftUI(.verticalAlignment(alignment)))
        }
    }
}
