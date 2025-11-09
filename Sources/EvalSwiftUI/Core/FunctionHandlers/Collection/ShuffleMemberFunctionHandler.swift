struct ShuffleMemberFunctionHandler: MemberFunctionHandler {
    let name = "shuffle"

    func call(
        resolver: ExpressionResolver,
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        scope: ExpressionScope,
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue {
        guard let baseValue else {
            throw SwiftUIEvaluatorError.invalidArguments("shuffle must be called on an array value.")
        }
        guard arguments.isEmpty else {
            throw SwiftUIEvaluatorError.invalidArguments("shuffle does not accept arguments.")
        }

        let target = try resolver.mutableArrayTarget(from: baseValue, functionName: "shuffle")
        let shuffled = resolver.shuffleElements(target.elements)
        target.writeBack?(shuffled)
        return .array(shuffled)
    }
}
