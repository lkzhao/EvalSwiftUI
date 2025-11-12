//
//  RuntimeFunctionScope.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/11/25.
//



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
