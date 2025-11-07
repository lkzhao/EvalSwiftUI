import SwiftUI

struct PaddingModifierBuilder: SwiftUIModifierBuilder {
    let name = "padding"

    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView {
        guard arguments.isEmpty else {
            throw SwiftUIEvaluatorError.invalidArguments("padding() does not take parameters yet.")
        }
        return AnyView(base.padding())
    }
}
