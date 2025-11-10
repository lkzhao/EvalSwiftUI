import Foundation

public final class RuntimeScope: CustomStringConvertible {
    private var storage: [String: RuntimeValue] = [:]
    private let parent: RuntimeScope?

    public enum ScopePreference {
        case localFirst
        case preferAncestor
    }

    public func define(_ name: String, value: RuntimeValue) {
        storage[name] = value
    }

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
    }

    public func set(_ name: String, value: RuntimeValue, preference: ScopePreference = .localFirst) {
        let targetScope: RuntimeScope

        switch preference {
        case .localFirst:
            targetScope = scope(containing: name, skippingCurrent: false) ?? self
        case .preferAncestor:
            targetScope = scope(containing: name, skippingCurrent: true)
                ?? scope(containing: name, skippingCurrent: false)
                ?? self
        }

        targetScope.storage[name] = value
    }

    public func get(_ name: String, preference: ScopePreference = .localFirst) -> RuntimeValue? {
        if preference == .localFirst, let value = storage[name] {
            return value
        }
        return parent?.get(name)
    }

    public var description: String {
        var desc = "RuntimeScope(storage: \(storage)"
        if let parent = parent {
            desc += ", parent: \(parent)"
        }
        desc += ")"
        return desc
    }

    private func scope(containing name: String, skippingCurrent: Bool) -> RuntimeScope? {
        if !skippingCurrent, storage[name] != nil {
            return self
        }
        return parent?.scope(containing: name, skippingCurrent: false)
    }
}
