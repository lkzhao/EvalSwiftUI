extension SwiftValue {
    @discardableResult
    func mutatingArrayValue(
        functionName: String,
        mutate: ([SwiftValue]) throws -> [SwiftValue]
    ) throws -> SwiftValue {
        switch self {
        case .state(let reference):
            let storage = reference.read()
            let elements = try storage.extractArrayElements(functionName: functionName)
            let mutated = try mutate(elements)
            reference.write(storage.wrappingArrayValue(with: mutated))
            return .array(mutated)
        case .binding(let binding):
            let storage = binding.read()
            let elements = try storage.extractArrayElements(functionName: functionName)
            let mutated = try mutate(elements)
            binding.write(storage.wrappingArrayValue(with: mutated))
            return .array(mutated)
        case .optional(let wrapped):
            guard let wrapped else {
                throw SwiftUIEvaluatorError.invalidArguments("\(functionName) cannot operate on nil optionals.")
            }
            return try wrapped.mutatingArrayValue(functionName: functionName, mutate: mutate)
        default:
            let elements = try arrayElements(functionName: functionName)
            let mutated = try mutate(elements)
            return .array(mutated)
        }
    }

    func arrayElements(functionName: String) throws -> [SwiftValue] {
        switch self {
        case .binding(let binding):
            return try binding.read().arrayElements(functionName: functionName)
        default:
            return try resolvingStateReference().extractArrayElements(functionName: functionName)
        }
    }

    private func extractArrayElements(functionName: String) throws -> [SwiftValue] {
        switch self {
        case .array(let elements):
            return elements
        case .optional(let wrapped):
            guard let wrapped else {
                throw SwiftUIEvaluatorError.invalidArguments("\(functionName) cannot operate on nil optionals.")
            }
            return try wrapped.extractArrayElements(functionName: functionName)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("\(functionName) is only supported on arrays.")
        }
    }

    private func wrappingArrayValue(with elements: [SwiftValue]) -> SwiftValue {
        let arrayValue: SwiftValue = .array(elements)
        switch self {
        case .optional(let wrapped):
            guard let wrapped else {
                return .optional(arrayValue)
            }
            return .optional(wrapped.wrappingArrayValue(with: elements))
        default:
            return arrayValue
        }
    }

    static func shuffleElements(_ elements: [SwiftValue]) -> [SwiftValue] {
        guard elements.count > 1 else {
            return elements
        }

        var shuffled = elements
        shuffled.shuffle()

        if elementsMatch(shuffled, elements) {
            let reversed = Array(elements.reversed())
            if !elementsMatch(reversed, elements) {
                return reversed
            }
        }

        return shuffled
    }

    private static func elementsMatch(_ lhs: [SwiftValue], _ rhs: [SwiftValue]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for (left, right) in zip(lhs, rhs) {
            if !left.equals(right) {
                return false
            }
        }
        return true
    }

    func dictionaryKey() throws -> String {
        switch resolvingStateReference() {
        case .string(let string):
            return string
        case .optional(let wrapped):
            guard let wrapped else {
                throw SwiftUIEvaluatorError.invalidArguments("Dictionary subscripts cannot use nil keys.")
            }
            return try wrapped.dictionaryKey()
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Dictionary subscripts require string keys.")
        }
    }

    var isStringLike: Bool {
        guard let unwrapped = unwrappedOptional() else {
            return false
        }
        if case .string = unwrapped {
            return true
        }
        return false
    }
}
