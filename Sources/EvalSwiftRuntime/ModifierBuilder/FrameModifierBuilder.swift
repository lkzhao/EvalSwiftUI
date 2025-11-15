import SwiftUI

public struct FrameModifierBuilder: RuntimeModifierBuilder {
    public let name = "frame"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeModifierDefinition(
                parameters: [
                    RuntimeParameter(name: "width", type: "Double", defaultValue: .void),
                    RuntimeParameter(name: "height", type: "Double", defaultValue: .void),
                    RuntimeParameter(
                        name: "alignment",
                        type: "Alignment",
                        defaultValue: .swiftUI(.alignment(.center))
                    )
                ],
                apply: { view, arguments, _ in
                    let alignment = arguments.value(named: "alignment")?.asAlignment ?? .center
                    return AnyView(
                        view.frame(
                            width: arguments.value(named: "width")?.asCGFloat,
                            height: arguments.value(named: "height")?.asCGFloat,
                            alignment: alignment
                        )
                    )
                }
            ),
            RuntimeModifierDefinition(
                parameters: [
                    RuntimeParameter(name: "minWidth", type: "Double", defaultValue: .void),
                    RuntimeParameter(name: "idealWidth", type: "Double", defaultValue: .void),
                    RuntimeParameter(name: "maxWidth", type: "Double", defaultValue: .void),
                    RuntimeParameter(name: "minHeight", type: "Double", defaultValue: .void),
                    RuntimeParameter(name: "idealHeight", type: "Double", defaultValue: .void),
                    RuntimeParameter(name: "maxHeight", type: "Double", defaultValue: .void),
                    RuntimeParameter(
                        name: "alignment",
                        type: "Alignment",
                        defaultValue: .swiftUI(.alignment(.center))
                    )
                ],
                apply: { view, arguments, _ in
                    let alignment = arguments.value(named: "alignment")?.asAlignment ?? .center
                    return AnyView(
                        view.frame(
                            minWidth: arguments.value(named: "minWidth")?.asCGFloat,
                            idealWidth: arguments.value(named: "idealWidth")?.asCGFloat,
                            maxWidth: arguments.value(named: "maxWidth")?.asCGFloat,
                            minHeight: arguments.value(named: "minHeight")?.asCGFloat,
                            idealHeight: arguments.value(named: "idealHeight")?.asCGFloat,
                            maxHeight: arguments.value(named: "maxHeight")?.asCGFloat,
                            alignment: alignment
                        )
                    )
                }
            )
        ]
    }
}
