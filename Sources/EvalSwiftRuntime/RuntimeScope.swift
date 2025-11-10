import Foundation

public final class RuntimeScope: CustomStringConvertible {
    private var storage: [String: RuntimeValue] = [:]
    private let parent: RuntimeScope?

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
    }

    public func set(_ name: String, value: RuntimeValue) {
        if storage[name] != nil {
            storage[name] = value
            return
        }
        if parent?.get(name) != nil {
            parent?.set(name, value: value)
            return
        }
        storage[name] = value
    }

    public func get(_ name: String) -> RuntimeValue? {
        if let value = storage[name] {
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
}
