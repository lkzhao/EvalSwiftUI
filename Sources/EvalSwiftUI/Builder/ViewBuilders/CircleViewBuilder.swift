import SwiftUI

struct CircleViewBuilder: SwiftUIViewBuilder {
    let name = "Circle"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard arguments.isEmpty else {
            throw SwiftUIEvaluatorError.invalidArguments("Circle does not accept arguments.")
        }
        return AnyView(Circle())
    }
}
