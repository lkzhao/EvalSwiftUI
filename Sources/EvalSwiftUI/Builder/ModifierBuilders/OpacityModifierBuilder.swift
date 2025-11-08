import SwiftUI

struct OpacityModifierBuilder: SwiftUIModifierBuilder {
    let name = "opacity"

    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView {
        guard let argument = arguments.first, arguments.count == 1 else {
            throw SwiftUIEvaluatorError.invalidArguments("opacity expects exactly one numeric argument.")
        }
        let opacity = try argument.value.asDouble(description: "opacity value")
        return AnyView(base.opacity(opacity))
    }
}
