import SwiftUI
import EvalSwiftIR

public protocol RuntimeScope: AnyObject, CustomStringConvertible {
    var storage: [String: RuntimeValue] { get set }
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
        storage[name] = value
    }

    public func set(_ name: String, value: RuntimeValue) throws {
        if let existing = storage[name] {
            if existing.valueType == .void {
                storage[name] = value
            } else {
                guard existing.valueType == value.valueType else {
                    throw RuntimeError.unsupportedAssignment(
                        "Type mismatch for '\(name)': expected \(existing.valueTypeDescription), got \(value.valueTypeDescription)"
                    )
                }
                storage[name] = value
            }
        } else if let parent {
            try parent.set(name, value: value)
        } else {
            throw RuntimeError.unknownIdentifier(name)
        }
    }

    public func get(_ name: String) throws -> RuntimeValue {
        if let value = storage[name] {
            return value
        }
        if let parent {
            return try parent.get(name)
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

    public func builder(named name: String) throws -> any RuntimeViewBuilder {
        let value = try get(name)
        guard case .viewBuilder(let builder) = value else {
            throw RuntimeError.unknownIdentifier(name)
        }
        return builder
    }

    func makeInstance(typeName: String, arguments: [RuntimeArgument] = []) throws -> RuntimeInstance {
        if let builder = try? builder(named: typeName) {
            return .init(builder: builder, arguments: arguments, parent: self)
        }
        if let type = try? type(named: typeName) {
            return try type.makeInstance()
        }
        throw RuntimeError.unknownView(typeName)
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
