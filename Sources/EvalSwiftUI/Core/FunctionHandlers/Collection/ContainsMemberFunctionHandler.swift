struct ContainsMemberFunctionHandler: MemberFunctionHandler {
    let name = "contains"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseValue else {
            throw SwiftUIEvaluatorError.invalidArguments("contains must be called on a collection value.")
        }
        guard arguments.count == 1, let argument = arguments.first else {
            throw SwiftUIEvaluatorError.invalidArguments("contains expects exactly one argument.")
        }
        return .bool(try containsValue(base: baseValue, element: argument.value))
    }

    private func containsValue(base: SwiftValue, element: SwiftValue) throws -> Bool {
        switch base.payload {
        case .array(let elements):
            return elements.contains { candidate in
                candidate.equals(element)
            }
        case .range(let rangeValue):
            let value = try element.asInt(description: "Range contains expressions")
            return rangeValue.contains(value)
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                return false
            }
            return try containsValue(base: unwrapped, element: element)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("contains is only supported on arrays and ranges.")
        }
    }
}
