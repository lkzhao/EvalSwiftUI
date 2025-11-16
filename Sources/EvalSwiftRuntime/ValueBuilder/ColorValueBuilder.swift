import SwiftUI

public struct ColorValueBuilder: RuntimeValueBuilder {
    public let name = "Color"
    public let definitions: [RuntimeBuilderDefinition]

    private static let namedColors: [(String, Color)] = [
        ("clear", .clear),
        ("black", .black),
        ("blue", .blue),
        ("cyan", .cyan),
        ("gray", .gray),
        ("green", .green),
        ("indigo", .indigo),
        ("mint", .mint),
        ("orange", .orange),
        ("pink", .pink),
        ("purple", .purple),
        ("red", .red),
        ("teal", .teal),
        ("white", .white),
        ("yellow", .yellow),
        ("brown", .brown),
        ("secondary", .secondary)
    ]

    public init() {
        var builderDefinitions: [RuntimeBuilderDefinition] = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "name", type: "String")
                ],
                build: { arguments, _ in
                    try Self.applyNamedColor(arguments: arguments)
                }
            ),
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "red", type: "Double"),
                    RuntimeParameter(name: "green", type: "Double"),
                    RuntimeParameter(name: "blue", type: "Double"),
                    RuntimeParameter(name: "opacity", type: "Double", defaultValue: .double(1.0))
                ],
                build: { arguments, _ in
                    try Self.applyRGBColor(arguments: arguments)
                }
            ),
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "color", type: "Color")
                ],
                build: { arguments, _ in
                    guard let color = arguments.value(named: "color")?.asColor else {
                        throw RuntimeError.invalidArgument("Color initializer expects a Color value.")
                    }
                    return .swiftUI(.color(color))
                }
            )
        ]

#if canImport(UIKit)
        builderDefinitions.append(
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "platformColor", type: "UIColor")
                ],
                build: { arguments, _ in
                    guard let platformColor = arguments.value(named: "platformColor")?.asPlatformColor else {
                        throw RuntimeError.invalidArgument("Color initializer expects a UIColor value.")
                    }
                    return .swiftUI(.color(platformColor.makeSwiftUIColor()))
                }
            )
        )
#elseif canImport(AppKit)
        builderDefinitions.append(
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "platformColor", type: "NSColor")
                ],
                build: { arguments, _ in
                    guard let platformColor = arguments.value(named: "platformColor")?.asPlatformColor else {
                        throw RuntimeError.invalidArgument("Color initializer expects an NSColor value.")
                    }
                    return .swiftUI(.color(platformColor.makeSwiftUIColor()))
                }
            )
        )
#endif

        definitions = builderDefinitions
    }

    private static func applyNamedColor(arguments: [RuntimeArgument]) throws -> RuntimeValue {
        guard let name = arguments.value(named: "name")?.asString?.lowercased(),
              let color = namedColors.first(where: { $0.0.lowercased() == name })?.1 else {
            throw RuntimeError.invalidArgument("Unknown color '\(arguments.value(named: "name")?.asString ?? "")'.")
        }
        return .swiftUI(.color(color))
    }

    private static func applyRGBColor(arguments: [RuntimeArgument]) throws -> RuntimeValue {
        guard
            let red = arguments.value(named: "red")?.asDouble,
            let green = arguments.value(named: "green")?.asDouble,
            let blue = arguments.value(named: "blue")?.asDouble
        else {
            throw RuntimeError.invalidArgument("Color(red:green:blue:) expects numeric components.")
        }
        let opacity = arguments.value(named: "opacity")?.asDouble ?? 1.0
        let color = Color(
            red: red,
            green: green,
            blue: blue,
            opacity: opacity
        )
        return .swiftUI(.color(color))
    }

    public func populate(type: RuntimeType) {
        for (name, color) in Self.namedColors {
            type.define(name, value: .swiftUI(.color(color)))
        }
    }
}
