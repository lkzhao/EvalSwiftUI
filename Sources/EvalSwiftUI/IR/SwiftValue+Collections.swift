extension SwiftValue {
    struct ArrayProxy {
        private let owner: SwiftValue

        init(owner: SwiftValue) {
            self.owner = owner
        }

        func elements() throws -> [SwiftValue] {
            switch owner.payload {
            case .array(let elements):
                return elements
            case .optional(let wrapped):
                guard let wrapped else {
                    throw SwiftUIEvaluatorError.invalidArguments("Array operations cannot operate on nil optional values.")
                }
                return try wrapped.arrayProxy().elements()
            default:
                throw SwiftUIEvaluatorError.invalidArguments("Array operations require an array value.")
            }
        }

        @discardableResult
        func mutate(_ transform: (inout [SwiftValue]) throws -> Void) throws -> [SwiftValue] {
            switch owner.payload {
            case .optional(let wrapped):
                guard let wrapped else {
                    throw SwiftUIEvaluatorError.invalidArguments("Array operations cannot operate on nil optional values.")
                }
                return try wrapped.arrayProxy().mutate(transform)
            case .array(var values):
                try transform(&values)
                owner.payload = .array(values)
                return values
            default:
                throw SwiftUIEvaluatorError.invalidArguments("Array operations require an array value.")
            }
        }
    }

    func arrayProxy() -> ArrayProxy {
        ArrayProxy(owner: self)
    }

    func dictionaryKey() throws -> String {
        switch payload {
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
        if case .string = unwrapped.payload {
            return true
        }
        return false
    }
}
