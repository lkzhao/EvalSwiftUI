import SwiftUI

public struct RectangleViewBuilder: RuntimeViewBuilder {
    public let typeName = "Rectangle"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard arguments.isEmpty else {
            throw RuntimeError.invalidViewArgument("Rectangle does not accept any arguments.")
        }
        return AnyView(Rectangle())
    }
}
