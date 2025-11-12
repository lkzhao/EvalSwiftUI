//
//  RuntimeGlobalScope.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/11/25.
//




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
