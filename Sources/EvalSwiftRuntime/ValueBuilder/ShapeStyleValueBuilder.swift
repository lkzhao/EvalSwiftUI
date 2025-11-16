import SwiftUI

public struct ShapeStyleValueBuilder: RuntimeValueBuilder {
    public let name = "ShapeStyle"
    public let definitions: [RuntimeBuilderDefinition] = []

    private static let styles: [(String, AnyShapeStyle)] = [
        ("clear", AnyShapeStyle(Color.clear)),
        ("black", AnyShapeStyle(Color.black)),
        ("blue", AnyShapeStyle(Color.blue)),
        ("cyan", AnyShapeStyle(Color.cyan)),
        ("gray", AnyShapeStyle(Color.gray)),
        ("green", AnyShapeStyle(Color.green)),
        ("indigo", AnyShapeStyle(Color.indigo)),
        ("mint", AnyShapeStyle(Color.mint)),
        ("orange", AnyShapeStyle(Color.orange)),
        ("pink", AnyShapeStyle(Color.pink)),
        ("purple", AnyShapeStyle(Color.purple)),
        ("red", AnyShapeStyle(Color.red)),
        ("teal", AnyShapeStyle(Color.teal)),
        ("white", AnyShapeStyle(Color.white)),
        ("yellow", AnyShapeStyle(Color.yellow)),
        ("brown", AnyShapeStyle(Color.brown)),
        ("primary", AnyShapeStyle(.primary)),
        ("secondary", AnyShapeStyle(.secondary)),
        ("tertiary", AnyShapeStyle(.tertiary)),
        ("quaternary", AnyShapeStyle(.quaternary)),
        ("ultraThinMaterial", AnyShapeStyle(Material.ultraThinMaterial)),
        ("thinMaterial", AnyShapeStyle(Material.thinMaterial)),
        ("regularMaterial", AnyShapeStyle(Material.regularMaterial)),
        ("thickMaterial", AnyShapeStyle(Material.thickMaterial)),
        ("ultraThickMaterial", AnyShapeStyle(Material.ultraThickMaterial))
    ]

    public init() {}

    public func populate(type: RuntimeType) {
        for (name, style) in Self.styles {
            type.define(name, value: .swiftUI(.shapeStyle(style)))
        }
    }
}
