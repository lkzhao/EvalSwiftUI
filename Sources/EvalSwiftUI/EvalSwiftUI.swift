// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public func evalSwiftUI(_ source: String) throws -> AnyView {
    let evaluator = SwiftUIEvaluator()
    let view = try evaluator.evaluate(source: source)
    return AnyView(view)
}

public func evalSwiftUI(_ source: () -> String) throws -> AnyView {
    let evaluator = SwiftUIEvaluator()
    let view = try evaluator.evaluate(source: source())
    return AnyView(view)
}
