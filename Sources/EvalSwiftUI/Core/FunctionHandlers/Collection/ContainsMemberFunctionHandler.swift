struct ContainsMemberFunctionHandler: MemberFunctionHandler {
    let name = "contains"

    func call(
        resolver: ExpressionResolver,
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        guard let baseValue else {
            throw SwiftUIEvaluatorError.invalidArguments("contains must be called on a collection value.")
        }
        guard arguments.count == 1, let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("contains expects exactly one argument.")
        }
        return .bool(try resolver.containsValue(base: baseValue, element: argument.value))
    }
}
