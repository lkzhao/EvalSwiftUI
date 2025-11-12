import Foundation

public final class RuntimeInstance: RuntimeScope, CustomStringConvertible {
    public private(set) var storage: [String: RuntimeValue] = [:]
    public let parent: RuntimeScope?
    var mutationHandler: MutationHandler?

    public typealias MutationHandler = (_ name: String, _ value: RuntimeValue) -> Void

    public func define(_ name: String, value: RuntimeValue) {
        storage[name] = value
    }

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
    }

    public func set(_ name: String, value: RuntimeValue) {
        if storage[name] != nil {
            storage[name] = value
            mutationHandler?(name, value)
        } else if let parent, parent.get(name) != nil {
            parent.set(name, value: value)
        } else {
            fatalError("Undefined variable '\(name)'")
        }
    }

    public func get(_ name: String) -> RuntimeValue? {
        if let value = storage[name] {
            return value
        }
        return parent?.get(name)
    }
}
