import SwiftUI
import EvalSwiftIR

public protocol RuntimeScope: AnyObject, CustomStringConvertible {
    typealias RuntimeScopeStorage = [String: [RuntimeValue.RuntimeValueType: RuntimeValue]]
    var storage: RuntimeScopeStorage { get set }
    var parent: RuntimeScope? { get }
    func define(_ name: String, value: RuntimeValue)
    func set(_ name: String, value: RuntimeValue) throws
    func get(_ name: String) throws -> RuntimeValue
}

extension RuntimeScope {
    public var parent: RuntimeScope? {
        return nil
    }

    public var description: String {
        var desc = "\(Swift.type(of: self))(storage: \(storage)"
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

    public var type: RuntimeType? {
        guard let type = self as? RuntimeType else {
            return parent?.type
        }
        return type
    }

    public var module: RuntimeModule? {
        guard let module = self as? RuntimeModule else {
            return parent?.module
        }
        return module
    }

    public func getFunction(_ name: String) throws -> RuntimeFunction {
        let value = try get(name)
        guard case .function(let function) = value else {
            throw RuntimeError.unknownFunction(name)
        }
        return function
    }

    public func callFunction(_ name: String, arguments: [RuntimeArgument] = []) throws -> RuntimeValue? {
        return try getFunction(name).invoke(arguments: arguments)
    }

    public func define(_ name: String, value: RuntimeValue) {
        storage[name, default: [:]][value.valueType] = value
    }

    public func set(_ name: String, value: RuntimeValue) throws {
        if let _ = storage[name, default: [:]][value.valueType] {
            storage[name, default: [:]][value.valueType] = value
        } else if let parent {
            try parent.set(name, value: value)
        } else {
            throw RuntimeError.unknownIdentifier(name)
        }
    }

    public func get(_ name: String) throws -> RuntimeValue {
        if let valueHolder = storage[name], valueHolder.count == 1, let value = valueHolder.values.first {
            return value
        }
        if let valueHolder = storage[name], valueHolder.count > 1 {
            throw RuntimeError.ambiguousIdentifier(name)
        }
        if let parent {
            return try parent.get(name)
        }
        throw RuntimeError.unknownIdentifier(name)
    }

    public func get(_ name: String, type: RuntimeValue.RuntimeValueType) throws -> RuntimeValue {
        if let valueHolder = storage[name], let value = valueHolder[type] {
            return value
        }
        if let parent {
            return try parent.get(name, type: type)
        }
        throw RuntimeError.unknownIdentifier(name)
    }

    public func getImplicitMember(_ name: String, expectedType: String?) throws -> RuntimeValue {
        var visited: Set<ObjectIdentifier> = []
        if let type = type,
           let value = type.lookupImplicitMember(named: name, expectedType: expectedType, visited: &visited) {
            return value
        }
        if let module = module,
           let value = module.lookupImplicitMember(named: name, expectedType: expectedType, visited: &visited) {
            return value
        }
        throw RuntimeError.unknownIdentifier(name)
    }

    public func type(named name: String) throws -> RuntimeType {
        let value = try get(name)
        guard case .type(let definition) = value else {
            throw RuntimeError.unknownIdentifier(name)
        }
        return definition
    }

    func define(binding: BindingIR) throws {
        if let initializer = binding.initializer {
            let rawValue = try ExpressionEvaluator.evaluate(initializer, scope: self) ?? .void
            let coercedValue = binding.coercedValue(from: rawValue)
            define(binding.name, value: coercedValue)
        } else {
            define(binding.name, value: .void)
        }
    }

    func define(parameter: FunctionParameterIR) throws {
        if let initializer = parameter.defaultValue {
            let value = try ExpressionEvaluator.evaluate(initializer, scope: self) ?? .void
            define(parameter.name, value: value)
        } else {
            define(parameter.name, value: .void)
        }
    }
}

func selectImplicitValue(from holder: RuntimeScope.RuntimeScopeStorage.Value) -> RuntimeValue? {
    holder.values.max(by: {
        $0.implicitPriority < $1.implicitPriority
    })
}
