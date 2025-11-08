import SwiftUI

struct RectangleViewBuilder: SwiftUIViewBuilder {
    let name = "Rectangle"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard arguments.isEmpty else {
            throw SwiftUIEvaluatorError.invalidArguments("Rectangle does not accept arguments.")
        }
        return AnyView(Rectangle())
    }
}
