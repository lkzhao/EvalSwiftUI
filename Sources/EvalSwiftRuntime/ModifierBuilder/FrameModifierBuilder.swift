import SwiftUI

public struct FrameModifierBuilder: RuntimeModifierBuilder {
    public let name = "frame"
    public let definitions: [RuntimeModifierDefinition] = [
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
                    view.frame(width: arguments.value(named: "width")?.asDouble.flatMap({ $0 }), height: arguments.value(named: "height")?.asDouble.flatMap({ $0 }), alignment: alignment)
                )
            }
        )
    ]
}
