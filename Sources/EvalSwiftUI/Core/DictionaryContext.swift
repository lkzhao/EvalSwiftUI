//
//  DictionaryContext.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/8/25.
//




public struct DictionaryContext: SwiftUIEvaluatorContext {
    var values: [String: SwiftValue]

    public init(values: [String : SwiftValue]) {
        self.values = values
    }

    public func value(for identifier: String) -> SwiftValue? {
        values[identifier]
    }
}


public struct ChainContext: SwiftUIEvaluatorContext {
    var contexts: [any SwiftUIEvaluatorContext]

    public init(contexts: [any SwiftUIEvaluatorContext]) {
        self.contexts = contexts
    }

    public func value(for identifier: String) -> SwiftValue? {
        for context in contexts {
            if let value = context.value(for: identifier) {
                return value
            }
        }
        return nil
    }
}
