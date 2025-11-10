import Foundation

public final class RuntimeScope {
    private var storage: [String: RuntimeValue] = [:]
    private let parent: RuntimeScope?

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
    }

    public func set(_ name: String, value: RuntimeValue) {
        storage[name] = value
    }

    public func get(_ name: String) -> RuntimeValue? {
        if let value = storage[name] {
            return value
        }
        return parent?.get(name)
    }
}
