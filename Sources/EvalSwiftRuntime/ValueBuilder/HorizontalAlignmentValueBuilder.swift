import SwiftUI

public struct HorizontalAlignmentValueBuilder: RuntimeValueBuilder {
    public let name = "HorizontalAlignment"
    public let definitions: [RuntimeBuilderDefinition]

    private static let alignments: [(String, HorizontalAlignment)] = [
        ("leading", .leading),
        ("center", .center),
        ("trailing", .trailing)
    ]

    public init() {
        self.definitions = []
    }

    public func populate(type: RuntimeType) {
        for (name, alignment) in Self.alignments {
            type.define(name, value: .swiftUI(.horizontalAlignment(alignment)))
        }
    }
}
