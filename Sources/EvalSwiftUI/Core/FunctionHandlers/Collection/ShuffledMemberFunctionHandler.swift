struct ShuffledMemberFunctionHandler: MemberFunctionHandler {
    let name = "shuffled"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseValue else {
            throw SwiftUIEvaluatorError.invalidArguments("shuffled must be called on an array value.")
        }
        guard arguments.isEmpty else {
            throw SwiftUIEvaluatorError.invalidArguments("shuffled does not accept arguments.")
        }

        let elements = try baseValue.asArray()
        let shuffled = elements.shuffled()
        return .array(shuffled)
    }
}
