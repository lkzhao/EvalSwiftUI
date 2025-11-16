import SwiftUI

public struct CapsuleValueBuilder: RuntimeValueBuilder {
    public let name = "Capsule"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(
                        name: "style",
                        type: "RoundedCornerStyle",
                        defaultValue: .swiftUI(.roundedCornerStyle(.circular))
                    )
                ],
                build: { arguments, _ in
                    let style = arguments.value(named: "style")?.asRoundedCornerStyle ?? .circular
                    return .swiftUI(.insettableShape(RuntimeInsettableShape(Capsule(style: style))))
                }
            )
        ]
    }
}
