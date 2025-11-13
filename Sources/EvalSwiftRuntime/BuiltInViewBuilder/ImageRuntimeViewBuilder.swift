import SwiftUI

public struct ImageRuntimeViewBuilder: RuntimeViewBuilder {
    public let typeName = "Image"

    public init() {
    }

    @MainActor
    public func makeSwiftUIView(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> AnyView {
        var systemName: String?
        var name: String?

        for parameter in arguments {
            if parameter.label == "systemName" {
                systemName = parameter.value.asString
                continue
            }

            if parameter.label == nil, name == nil {
                name = parameter.value.asString
            }
        }

        if let systemName {
            guard !systemName.isEmpty else {
                throw RuntimeError.invalidViewArgument("Image(systemName:) expects a non-empty symbol name.")
            }
            return AnyView(Image(systemName: systemName))
        }

        if let name {
            guard !name.isEmpty else {
                throw RuntimeError.invalidViewArgument("Image expects a non-empty name.")
            }
            return AnyView(Image(name))
        }

        throw RuntimeError.invalidViewArgument("Image requires either a resource name or systemName parameter.")
    }
}
