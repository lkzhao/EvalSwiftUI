import SwiftUI

struct OpacityModifierHandler: MemberFunctionHandler {
    let name = "opacity"

    func call(
        resolver: ExpressionResolver,
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        guard let baseView = baseValue?.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("opacity modifier requires a view receiver.")
        }
        guard let argument = arguments.first, arguments.count == 1 else {
            throw SwiftUIEvaluatorError.invalidArguments("opacity expects exactly one numeric argument.")
        }
        let opacity = try argument.value.asDouble(description: "opacity value")
        return .view(AnyView(baseView.opacity(opacity)))
    }
}
