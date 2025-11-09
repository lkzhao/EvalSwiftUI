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

        let shuffled = try baseValue.asArray().shuffled()
        baseValue.mutatePayload {
            $0 = .array(shuffled)
        }
        return .array(shuffled)
    }
}
