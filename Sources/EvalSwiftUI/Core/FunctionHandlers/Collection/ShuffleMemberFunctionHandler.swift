struct ShuffleMemberFunctionHandler: MemberFunctionHandler {
    let name = "shuffle"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseValue else {
            throw SwiftUIEvaluatorError.invalidArguments("shuffle must be called on an array value.")
        }
        guard arguments.isEmpty else {
            throw SwiftUIEvaluatorError.invalidArguments("shuffle does not accept arguments.")
        }

        return try baseValue.mutatingArrayValue(functionName: "shuffle") { elements in
            SwiftValue.shuffleElements(elements)
        }
    }
}
