import SwiftUI

public struct AlignmentValueBuilder: RuntimeValueBuilder {
    public let name = "Alignment"
    public let definitions: [RuntimeBuilderDefinition]

    private static let alignments: [(String, Alignment)] = [
        ("center", .center),
        ("leading", .leading),
        ("trailing", .trailing),
        ("top", .top),
        ("bottom", .bottom),
        ("topLeading", .topLeading),
        ("topTrailing", .topTrailing),
        ("bottomLeading", .bottomLeading),
        ("bottomTrailing", .bottomTrailing)
    ]

    public init() {
        self.definitions = []
    }

    public func populate(type: RuntimeType) {
        for (name, alignment) in Self.alignments {
            type.define(name, value: .swiftUI(.alignment(alignment)))
        }
    }
}
