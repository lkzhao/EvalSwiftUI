import SwiftUI

public struct BlendModeValueBuilder: RuntimeValueBuilder {
    public let name = "BlendMode"
    public let definitions: [RuntimeBuilderDefinition] = []

    private static let blendModes: [(String, BlendMode)] = [
        ("normal", .normal),
        ("multiply", .multiply),
        ("screen", .screen),
        ("overlay", .overlay),
        ("darken", .darken),
        ("lighten", .lighten),
        ("colorDodge", .colorDodge),
        ("colorBurn", .colorBurn),
        ("softLight", .softLight),
        ("hardLight", .hardLight),
        ("difference", .difference),
        ("exclusion", .exclusion),
        ("hue", .hue),
        ("saturation", .saturation),
        ("color", .color),
        ("luminosity", .luminosity),
        ("sourceAtop", .sourceAtop),
        ("destinationOver", .destinationOver),
        ("destinationOut", .destinationOut),
        ("plusDarker", .plusDarker),
        ("plusLighter", .plusLighter)
    ]

    public init() {}

    public func populate(type: RuntimeType) {
        for (name, mode) in Self.blendModes {
            type.define(name, value: .swiftUI(.blendMode(mode)))
        }
    }
}
