import Foundation

public protocol RuntimeScope: AnyObject, CustomStringConvertible {
    var storage: [String: RuntimeValue] { get }
    var parent: RuntimeScope? { get }
    // TODO: define/set/get should receive a type to distinguish between same variable names with different types
    func define(_ name: String, value: RuntimeValue)
    func set(_ name: String, value: RuntimeValue)
    func get(_ name: String) -> RuntimeValue?
}

extension RuntimeScope {
    public var description: String {
        var desc = "RuntimeInstance(storage: \(storage)"
        if let parent = parent {
            desc += ", parent: \(parent)"
        }
        desc += ")"
        return desc
    }
    public var instance: RuntimeInstance? {
        guard let instance = self as? RuntimeInstance else {
            return parent?.instance
        }
        return instance
    }
    public func callMethod(_ name: String, arguments: [RuntimeArgument] = []) throws -> RuntimeValue {
        guard let value = get(name), case .function(let function) = value else {
            throw RuntimeError.unknownFunction(name)
        }
        return try function.invoke(arguments: arguments, scope: self)
    }
}

public final class RuntimeGlobalScope: RuntimeScope {
    public private(set) var storage: [String: RuntimeValue] = [:]
    public let parent: RuntimeScope? = nil

    public func define(_ name: String, value: RuntimeValue) {
        storage[name] = value
    }

    public init() {}

    public func set(_ name: String, value: RuntimeValue) {
        if storage[name] != nil {
            storage[name] = value
        } else {
            fatalError("Undefined variable '\(name)'")
        }
    }

    public func get(_ name: String) -> RuntimeValue? {
        storage[name]
    }
}

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

public final class RuntimeFunctionScope: RuntimeScope {
    public private(set) var storage: [String: RuntimeValue] = [:]
    public let parent: RuntimeScope?

    public func define(_ name: String, value: RuntimeValue) {
        storage[name] = value
    }

    public init(parent: RuntimeScope?) {
        self.parent = parent
    }

    public func set(_ name: String, value: RuntimeValue) {
        if storage[name] != nil {
            storage[name] = value
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
