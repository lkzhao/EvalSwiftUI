final class ScopedEvaluatorContext: SwiftUIEvaluatorContext {
    private let scopeBox: ScopeBox?
    private let base: (any SwiftUIEvaluatorContext)?

    init(scopeBox: ScopeBox?, base: (any SwiftUIEvaluatorContext)?) {
        self.scopeBox = scopeBox
        self.base = base
    }

    func value(for identifier: String) -> SwiftValue? {
        if let scoped = scopeBox?.storage[identifier] {
            return scoped
        }
        return base?.value(for: identifier)
    }

    func setValue(_ value: SwiftValue?, for identifier: String) {
        if scopeBox?.setValue(value, for: identifier) == true {
            return
        }
        base?.setValue(value, for: identifier)
    }
}

extension ScopedEvaluatorContext {
    static func withMutableScope(
        _ scopeBox: ScopeBox,
        base: (any SwiftUIEvaluatorContext)?
    ) -> ScopedEvaluatorContext {
        ScopedEvaluatorContext(scopeBox: scopeBox, base: base)
    }

    static func readOnlyScope(
        scope: ExpressionScope,
        base: (any SwiftUIEvaluatorContext)?
    ) -> ScopedEvaluatorContext {
        let box = ScopeBox(storage: scope.cloningForCapture(), isMutable: false)
        return ScopedEvaluatorContext(scopeBox: box, base: base)
    }
}

final class ScopeBox {
    var storage: ExpressionScope
    private let isMutable: Bool

    init(storage: ExpressionScope, isMutable: Bool) {
        self.storage = storage
        self.isMutable = isMutable
    }

    func setValue(_ value: SwiftValue?, for identifier: String) -> Bool {
        guard isMutable, storage.keys.contains(identifier) else {
            return false
        }
        if let value {
            if value.stateIdentifierValue() != nil {
                storage[identifier] = value
            } else {
                storage[identifier] = value.copy()
            }
        } else {
            storage[identifier] = nil
        }
        return true
    }
}
