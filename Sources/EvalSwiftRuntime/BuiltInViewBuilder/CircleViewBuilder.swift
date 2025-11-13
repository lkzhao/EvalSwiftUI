import SwiftUI

public struct CircleViewBuilder: RuntimeViewBuilder {
    public let typeName = "Circle"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard arguments.isEmpty else {
            throw RuntimeError.invalidViewArgument("Circle does not accept any arguments.")
        }
        return AnyView(Circle())
    }
}
