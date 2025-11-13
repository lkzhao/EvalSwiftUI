import SwiftUI

public struct SpacerViewBuilder: RuntimeViewBuilder {
    public let typeName = "Spacer"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var minLength: CGFloat?

        for argument in arguments {
            if let label = argument.label {
                guard label == "minLength" else {
                    throw RuntimeError.invalidViewArgument("Spacer only supports the minLength argument.")
                }
            }

            guard let lengthValue = argument.value.asDouble else {
                throw RuntimeError.invalidViewArgument("minLength must be convertible to a number.")
            }
            minLength = CGFloat(lengthValue)
        }

        return AnyView(Spacer(minLength: minLength))
    }
}
