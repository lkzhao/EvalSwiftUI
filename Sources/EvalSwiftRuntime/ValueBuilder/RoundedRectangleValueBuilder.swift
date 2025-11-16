import SwiftUI

public struct RoundedRectangleValueBuilder: RuntimeValueBuilder {
    public let name = "RoundedRectangle"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        self.definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "cornerRadius", type: "Double"),
                    RuntimeParameter(
                        name: "style",
                        type: "RoundedCornerStyle",
                        defaultValue: .swiftUI(.roundedCornerStyle(.continuous))
                    )
                ],
                build: { arguments, _ in
                    guard let cornerRadius = arguments.value(named: "cornerRadius")?.asCGFloat else {
                        throw RuntimeError.invalidArgument(
                            "RoundedRectangle(cornerRadius:) expects a numeric value."
                        )
                    }
                    let style = arguments.value(named: "style")?.asRoundedCornerStyle ?? .continuous
                    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: style)
                    return .swiftUI(.insettableShape(RuntimeInsettableShape(shape)))
                }
            )
        ]
    }
}
