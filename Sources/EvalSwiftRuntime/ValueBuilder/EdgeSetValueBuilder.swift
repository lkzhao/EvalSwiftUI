import SwiftUI

public struct EdgeSetValueBuilder: RuntimeValueBuilder {
    public let name = "Edge.Set"
    public let definitions: [RuntimeBuilderDefinition] = []

    public init() {}

    public func populate(type: RuntimeType) {
        let values: [(String, Edge.Set)] = [
            ("top", .top),
            ("bottom", .bottom),
            ("leading", .leading),
            ("trailing", .trailing),
            ("horizontal", .horizontal),
            ("vertical", .vertical),
            ("all", .all)
        ]
        for (name, set) in values {
            type.define(name, value: .swiftUI(.edgeSet(set)))
        }
    }
}
