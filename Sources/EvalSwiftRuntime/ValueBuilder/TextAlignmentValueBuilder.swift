import SwiftUI

public struct TextAlignmentValueBuilder: RuntimeValueBuilder {
    public let name = "TextAlignment"
    public let definitions: [RuntimeBuilderDefinition] = []

    public init() {}

    public func populate(type: RuntimeType) {
        let alignments: [(String, TextAlignment)] = [
            ("leading", .leading),
            ("center", .center),
            ("trailing", .trailing)
        ]
        for (name, alignment) in alignments {
            type.define(name, value: .swiftUI(.textAlignment(alignment)))
        }
    }
}
