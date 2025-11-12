//
//  RuntimeScope.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/11/25.
//

public protocol RuntimeScope: AnyObject, CustomStringConvertible {
    var storage: [String: RuntimeValue] { get set }
    var parent: RuntimeScope? { get }
    func define(_ name: String, value: RuntimeValue)
    func set(_ name: String, value: RuntimeValue) throws
    func get(_ name: String) throws -> RuntimeValue
}

extension RuntimeScope {
    public var description: String {
        var desc = "\(type(of: self))(storage: \(storage)"
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
    public func callMethod(_ name: String, arguments: [RuntimeArgument] = []) throws -> RuntimeValue? {
        let value = try get(name)
        guard case .function(let function) = value else {
            throw RuntimeError.unknownFunction(name)
        }
        return try function.invoke(arguments: arguments, scope: self)
    }

    public func define(_ name: String, value: RuntimeValue) {
        storage[name] = value
    }

    public func set(_ name: String, value: RuntimeValue) throws {
        if let existing = storage[name] {
            if existing.runtimeType == .void {
                storage[name] = value
            } else {
                guard existing.runtimeType == value.runtimeType else {
                    throw RuntimeError.unsupportedAssignment(
                        "Type mismatch for '\(name)': expected \(existing.runtimeTypeDescription), got \(value.runtimeTypeDescription)"
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
}
