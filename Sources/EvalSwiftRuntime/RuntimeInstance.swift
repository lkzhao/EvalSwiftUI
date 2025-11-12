import Foundation

public final class RuntimeInstance: CustomStringConvertible {
    private var storage: [String: RuntimeValue] = [:]
    private let parent: RuntimeInstance?
    var mutationHandler: MutationHandler?

    public enum ScopePreference {
        case localFirst
        case preferAncestor
    }

    public typealias MutationHandler = (_ name: String, _ value: RuntimeValue) -> Void

    public func define(_ name: String, value: RuntimeValue) {
        storage[name] = value
    }

    public init(parent: RuntimeInstance? = nil) {
        self.parent = parent
    }

    public func set(_ name: String, value: RuntimeValue, preference: ScopePreference = .localFirst) {
        let targetInstance: RuntimeInstance

        switch preference {
        case .localFirst:
            targetInstance = instance(containing: name, skippingCurrent: false) ?? self
        case .preferAncestor:
            targetInstance = instance(containing: name, skippingCurrent: true)
                ?? instance(containing: name, skippingCurrent: false)
                ?? self
        }

        targetInstance.storage[name] = value
        targetInstance.mutationHandler?(name, value)
    }

    public func get(_ name: String, preference: ScopePreference = .localFirst) -> RuntimeValue? {
        switch preference {
        case .localFirst:
            if let value = storage[name] {
                return value
            }
            return parent?.get(name)
        case .preferAncestor:
            if let ancestorValue = parent?.get(name) {
                return ancestorValue
            }
            return storage[name]
        }
    }

    public func callMethod(_ name: String, arguments: [RuntimeParameter] = []) throws -> RuntimeValue {
        guard let value = get(name, preference: .preferAncestor),
              case .function(let function) = value else {
            throw RuntimeError.unknownFunction(name)
        }
        return try function.invoke(arguments: arguments, instance: self)
    }

    public var description: String {
        var desc = "RuntimeInstance(storage: \(storage)"
        if let parent = parent {
            desc += ", parent: \(parent)"
        }
        desc += ")"
        return desc
    }

    private func instance(containing name: String, skippingCurrent: Bool) -> RuntimeInstance? {
        if !skippingCurrent, storage[name] != nil {
            return self
        }
        return parent?.instance(containing: name, skippingCurrent: false)
    }
}
