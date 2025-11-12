//
//  RuntimeGlobalScope.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/11/25.
//




public final class RuntimeGlobalScope: RuntimeScope {
    public var storage: [String: RuntimeValue] = [:]
    public let parent: RuntimeScope? = nil

    public init() {}
}
