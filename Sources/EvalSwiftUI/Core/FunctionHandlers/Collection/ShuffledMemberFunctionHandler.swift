struct ShuffledMemberFunctionHandler: MemberFunctionHandler {
    let name = "shuffled"

    func call(
        resolver: ExpressionResolver,
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        guard let baseValue else {
            throw SwiftUIEvaluatorError.invalidArguments("shuffled must be called on an array value.")
        }
        guard arguments.isEmpty else {
            throw SwiftUIEvaluatorError.invalidArguments("shuffled does not accept arguments.")
        }

        let elements = try resolver.arrayElements(from: baseValue, functionName: "shuffled")
        let shuffled = resolver.shuffleElements(elements)
        return .array(shuffled)
    }
}
