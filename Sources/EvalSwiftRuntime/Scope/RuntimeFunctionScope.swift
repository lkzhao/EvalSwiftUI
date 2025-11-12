//
//  RuntimeFunctionScope.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/11/25.
//



public final class RuntimeFunctionScope: RuntimeScope {
    public var storage: [String: RuntimeValue] = [:]
    public let parent: RuntimeScope?

    public init(parent: RuntimeScope?) {
        self.parent = parent
    }
}
