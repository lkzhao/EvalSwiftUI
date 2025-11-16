import SwiftUI

public struct UnitPointValueBuilder: RuntimeValueBuilder {
    public let name = "UnitPoint"
    public let definitions: [RuntimeBuilderDefinition] = []

    private static let points: [(String, UnitPoint)] = [
        ("center", .center),
        ("top", .top),
        ("topLeading", .topLeading),
        ("topTrailing", .topTrailing),
        ("bottom", .bottom),
        ("bottomLeading", .bottomLeading),
        ("bottomTrailing", .bottomTrailing),
        ("leading", .leading),
        ("trailing", .trailing)
    ]

    public init() {}

    public func populate(type: RuntimeType) {
        for (name, point) in Self.points {
            type.define(name, value: .swiftUI(.unitPoint(point)))
        }
    }
}
